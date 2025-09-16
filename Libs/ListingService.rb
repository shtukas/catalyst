# alter table listing rename column line to listing_lines;
# alter table listing add column mikuType TEXT NOT NULL default "";

=begin

CREATE TABLE random (value REAL);
CREATE TABLE listing (itemuuid TEXT PRIMARY KEY NOT NULL, utime REAL NOT NULL, item TEXT NOT NULL, mikuType TEXT NOT NULL, px17 TEXT NOT NULL, listing_lines TEXT NOT NULL);

itemuuid      : string
utime         : unixtime with decimals of the last update of that record
item          : json encoded object
mikuType      : string
px17          : json encoded object
listing_lines : json encoded array

position
{
    "type" : "compute"
}
{
    "type"  : "overriden"
    "value" : float
    "expiry": unixtime
}

=end

class ListingService

    # ------------------------------------------------------
    # Basic IO management

    # ListingService::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/databases/index0-listing"
    end

    # ListingService::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(ListingService::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
            .select{|filepath| !File.basename(filepath).include?("sync-conflict") }
            .sort
    end

    # ListingService::ensureContentAddressing(filepath1)
    def self.ensureContentAddressing(filepath1)
        filename2 = "#{Digest::SHA1.file(filepath1).hexdigest}.sqlite3"
        filepath2 = "#{ListingService::directory()}/#{filename2}"
        return filepath1 if filepath1 == filepath2
        FileUtils.mv(filepath1, filepath2)
        filepath2
    end

    # ListingService::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{ListingService::directory()}/#{filename}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        # Because we are doing content addressing we need the newly created database to be distinct that one that could already be there.
        db.execute("CREATE TABLE random (value REAL)", [])
        db.execute("insert into random (value) values (?)", [rand])
        db.execute("CREATE TABLE listing (itemuuid TEXT PRIMARY KEY NOT NULL, utime REAL NOT NULL, item TEXT NOT NULL, mikuType TEXT NOT NULL, px17 TEXT NOT NULL, listing_lines TEXT NOT NULL)", [])
        db.commit
        db.close
        ListingService::ensureContentAddressing(filepath)
    end

    # ListingService::mergeTwoDatabaseFiles(filepath1, filepath2) # -> filepath of the 
    def self.mergeTwoDatabaseFiles(filepath1, filepath2)
        # The logic here is to read the items from filepath2 and 
        # possibly add them to filepath1, if either:
        #   - there was no equivalent in filepath1
        #   - it's a newer record than the one in filepath1
        ListingService::extractDataFromFile(filepath2).each{|entry2|
            shouldInject = false
            entry1 = ListingService::extractEntryOrNullFromFilepath(filepath1, entry2["item"]["uuid"])
            if entry1 then
                # We have entry1 and entry2
                # We perform the update if entry2 is newer than entry1
                if entry2["utime"] > entry1["utime"] then
                    shouldInject = true
                end
            else
                # entry1 is null, we inject entry2 into filepath1
                shouldInject = true
            end
            if shouldInject then
                ListingService::insertUpdateEntryComponents2(filepath1, entry2["utime"], entry2["item"], entry2["px17"], entry2["listing_lines"])
            end
        }
        # Then when we are done, we delete filepath2
        FileUtils::rm(filepath2)
        ListingService::ensureContentAddressing(filepath1)
    end

    # ListingService::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = ListingService::filepaths()

        # This case should not really happen (anymore), so if the condition 
        # is true, let's error noisily.
        if filepaths.size == 0 then
            # return ListingService::initiateDatabaseFile()
            raise "(error: 36181da9)"
        end

        if filepaths.size == 1 then
            return filepaths[0]
        end

        filepath1 = filepaths.shift
        filepaths.each{|filepath|
            # The logic here is to read the items from filepath2 and 
            # possibly add them to filepath1.
            # We get an updated filepath1 because of content addressing.
            filepath1 = ListingService::mergeTwoDatabaseFiles(filepath1, filepath)
        }
        filepath1
    end

    # ------------------------------------------------------
    # Database Ops

    # ListingService::insertUpdateEntryComponents2(filepath, utime, item, px17, listing_lines)
    def self.insertUpdateEntryComponents2(filepath, utime, item, px17, listing_lines)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [item["uuid"]])
        db.execute("insert into listing (itemuuid, utime, item, mikuType, px17, listing_lines) values (?, ?, ?, ?, ?, ?)", [item["uuid"], utime, JSON.generate(item), item["mikuType"], JSON.generate(px17), JSON.generate(listing_lines)])
        db.commit
        db.close
    end

    # ListingService::insertUpdateEntryComponents1(item, px17, listing_lines)
    def self.insertUpdateEntryComponents1(item, px17, listing_lines)
        filepath = ListingService::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [item["uuid"]])
        db.execute("insert into listing (itemuuid, utime, item, mikuType, px17, listing_lines) values (?, ?, ?, ?, ?, ?)", [item["uuid"], Time.new.to_f, JSON.generate(item), item["mikuType"], JSON.generate(px17), JSON.generate(listing_lines)])
        db.commit
        db.close
        ListingService::ensureContentAddressing(filepath)
    end

    # ------------------------------------------------------
    # Data (Internals)

    # ListingService::extractDataFromFile(filepath)
    def self.extractDataFromFile(filepath)
        data = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from listing", []) do |row|
            data << {
                "itemuuid" => row["itemuuid"],
                "utime"    => row["utime"],
                "item"     => JSON.parse(row["item"]),
                "mikuType" => row["mikuType"],
                "px17"     => JSON.parse(row["px17"]),
                "listing_lines" => JSON.parse(row["listing_lines"])
            }
        end
        db.close
        data
    end

    # ListingService::extractEntryOrNullFromFilepath(filepath, itemuuid)
    def self.extractEntryOrNullFromFilepath(filepath, itemuuid)
        data = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from listing where itemuuid=?", [itemuuid]) do |row|
            item = JSON.parse(row["item"])
            data = {
                "itemuuid" => row["itemuuid"],
                "utime"    => row["utime"],
                "item"     => item,
                "mikuType" => row["mikuType"],
                "px17"     => JSON.parse(row["px17"]),
                "listing_lines" => JSON.parse(row["listing_lines"])
            }
        end
        db.close
        data
    end

    # ------------------------------------------------------
    # Data

    # ListingService::getEntryOrNull(itemuuid)
    def self.getEntryOrNull(itemuuid)
        ListingService::extractEntryOrNullFromFilepath(ListingService::getDatabaseFilepath(), itemuuid)
    end

    # ListingService::hasItem(itemuuid)
    def self.hasItem(itemuuid)
        answer = false
        filepath = ListingService::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from listing where itemuuid=?", [itemuuid]) do |row|
            answer = true
        end
        db.close
        answer
    end

    # ListingService::getPx17(itemuuid)
    def self.getPx17(itemuuid)
        px17 = nil
        filepath = ListingService::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from listing where itemuuid=?", [itemuuid]) do |row|
            px17 = JSON.parse(row["px17"])
        end
        db.close
        if px17.nil? then
            raise "(error: d330c4f1)"
        end
        px17
    end

    # ListingService::decideListingLines(item)
    def self.decideListingLines(item)
        # Edits to this function should be mirrored in FrontPage::toString2(store, item)
        return [] if item.nil?
        lines = []
        line = "STORE-PREFIX #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil::suffix2(item)}"

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        lines << line

        if item["uxpayload-b4e4"] and item["uxpayload-b4e4"]["type"] == "breakdown" then
            item["uxpayload-b4e4"]["lines"].each{|l|
                lines << "         #{l}"
            }
        end

        lines
    end

    # ListingService::isListable(item)
    def self.isListable(item)
        if item["mikuType"] == "NxEvent" then
            return true
        end

        if item["mikuType"] == "NxLine" then
            return true
        end

        if item["mikuType"] == "NxLambda" then
            return true
        end

        if item["mikuType"] == "Wave" then
            return true
        end

        if item["mikuType"] == "NxTask" then
            return DoNotShowUntil::isVisible(item["uuid"])
        end

        if item["mikuType"] == "NxOnDate" then
            return item["date"][0, 10] <= CommonUtils::today()
        end

        if item["mikuType"] == "NxAnniversary" then
            return item["next_celebration"] <= CommonUtils::today()
        end

        if item["mikuType"] == "NxBackup" then
            return true
        end

        if item["mikuType"] == "NxProject" then
            return true
        end

        if item["mikuType"] == "NxDeadline" then
            return true
        end

        if item["mikuType"] == "NxDeleted" then
            return false
        end

        if item["mikuType"] == "NxOpen" then
            return true
        end

        puts "I do not know how to ListingService::isListable(#{JSON.pretty_generate(item)})"
        raise "(error: 3ae9fe86)"
    end

    # ListingService::memoizedRandomPositionInInterval(item, x0, x1)
    def self.memoizedRandomPositionInInterval(item, x0, x1)
        r = XCache::getOrNull("673474f9-f949-4eb1-866c-fb56090c5265:#{item["uuid"]}:#{x0}:#{x1}")
        r = if r then
            r.to_f
        else
            r = rand
            XCache::set("673474f9-f949-4eb1-866c-fb56090c5265:#{item["uuid"]}:#{x0}:#{x1}", r)
            r
        end
        x0 + r*(x1 - x0)
    end

    # ListingService::realLineTo01Increasing(x)
    def self.realLineTo01Increasing(x)
        (2 + Math.atan(x)).to_f/10
    end

    # ListingService::realLineTo01Decreasing(x)
    def self.realLineTo01Decreasing(x)
        1 - ListingService::realLineTo01Increasing(x)
    end

    # ListingService::itemToCyclingPosition(item, a, b)
    def self.itemToCyclingPosition(item, a , b)
        if item["phase-1208"].nil? then
            item["phase-1208"] = rand * 3.14 * 2
            Items::setAttribute(item["uuid"], "phase-1208", item["phase-1208"])
        end
        middlePoint = (a+b).to_f/2
        radius = (b-a).to_f/2
        cursor = Time.new.to_f/86400
        middlePoint + radius * Math.sin(cursor + item["phase-1208"])
    end

    # ListingService::entries()
    def self.entries()
        ListingService::extractDataFromFile(ListingService::getDatabaseFilepath())
    end

    # ListingService::firstPositionInDatabase()
    def self.firstPositionInDatabase()
        entries = ListingService::entries()
        return 1 if entries.empty?
        entries.map{|entry| ListingService::decidePositionForEntry(entry) }.min
    end

    # ListingService::computePositionForItem(item)
    def self.computePositionForItem(item)
        # We return null if the item shouild not be listed at this time, because it has 
        # reached a time target or something.

        # There should not be negative positions

        # NxOpen
        # 0.050 -> 0.100

        # NxEvents
        # 0.100 -> 0.150

        # Sorting
        # 0.200 -> 0.250

        # Natural Positions
        # 0.260 -> 0.280 NxAnniversary
        # 0.280 -> 0.300 NxLambda
        # 0.300 -> 0.320 Wave sticky
        # 0.320 -> 0.350 Wave interruption
        # 0.400 -> 0.450 NxBackup
        # 0.500 -> 0.600 NxOnDate
        # 0.650 -> 0.680 NxDeadline
        # 0.750 -> 0.780 NxProject
        # 0.800 -> 0.880 NxTask

        # 0.390 -> 1.000 Wave (overlay)

        if item["mikuType"] == "NxOpen" then
            d1 = item["unixtime"] - 1757661467
            d2 = ListingService::realLineTo01Increasing(d1)
            return 0.050 + d2.to_f/100
        end

        if item["mikuType"] == "NxEvent" then
            d1 = DateTime.parse("#{item["date"]}T17:28:01Z").to_time.to_i - 1757661467
            d2 = ListingService::realLineTo01Increasing(d1)
            return 0.100 + d2.to_f/100
        end

        if item["mikuType"] == "NxLine" then
            return rand
        end

        if item["mikuType"] == "NxLambda" then
            return ListingService::memoizedRandomPositionInInterval(item, 0.28, 0.30)
        end

        if item["mikuType"] == "Wave" then
            if item["interruption"] then
                return ListingService::memoizedRandomPositionInInterval(item, 0.32, 0.35)
            end
            if item["nx46"]["type"] == "sticky" then
                return ListingService::memoizedRandomPositionInInterval(item, 0.30, 0.32)
            end
            return ListingService::itemToCyclingPosition(item, 0.390, 1.000)
        end

        if item["mikuType"] == "NxAnniversary" then
            return ListingService::memoizedRandomPositionInInterval(item, 0.26, 0.28)
        end

        if item["mikuType"] == "NxBackup" then
            return ListingService::memoizedRandomPositionInInterval(item, 0.40, 0.45)
        end

        if item["mikuType"] == "NxProject" then
            return ListingService::memoizedRandomPositionInInterval(item, 0.75, 0.78)
        end

        if item["mikuType"] == "NxDeadline" then
            dayNumber = (DateTime.parse("#{item["date"]}T00:00:00Z").to_time.to_f/86400).to_i - 20336
            idx = dayNumber + ListingService::realLineTo01Increasing(item["unixtime"]-1757069447)
            return 0.66 + ListingService::realLineTo01Increasing(idx).to_f/1000
        end

        if item["mikuType"] == "NxOnDate" then
            dayNumber = (DateTime.parse("#{item["date"]}T00:00:00Z").to_time.to_f/86400).to_i - 20336
            idx = dayNumber + ListingService::realLineTo01Increasing(item["unixtime"]-1757069447)
            return 0.51 + ListingService::realLineTo01Increasing(idx).to_f/1000
        end

        if item["mikuType"] == "NxTask" then
            level = item["priorityLevel48"]
            primaryPosition = PriorityLevels::primaryPosition(level)
            secondaryPosition = BankData::recoveredAverageHoursPerDay(item["uuid"]).to_f/1_000_000
            return primaryPosition + secondaryPosition
        end

        puts "I do not know how to ListingService::computePositionForItem(#{JSON.pretty_generate(item)})"
        raise "(error: df253fc4)"
    end

    # ListingService::decidePositionForEntry(entry)
    def self.decidePositionForEntry(entry)
        px17 = entry["px17"]
        if px17["type"] == "compute" then
            return ListingService::computePositionForItem(entry["item"])
        end
        if px17["type"] == "overriden" then
            if Time.new.to_i < px17["expiry"] then
                return px17["value"]
            else
                return ListingService::computePositionForItem(entry["item"])
            end
        end
    end

    # ------------------------------------------------------
    # Setters

    # ListingService::setPx17(itemuuid, px17)
    def self.setPx17(itemuuid, px17)
        return if !ListingService::hasItem(itemuuid)
        filepath = ListingService::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("update listing set px17=?, utime=? where itemuuid=?", [JSON.generate(px17), Time.new.to_f, itemuuid])
        db.commit
        db.close
        ListingService::ensureContentAddressing(filepath)
    end

    # ListingService::insertUpdateItemAtPx17(item, px17)
    def self.insertUpdateItemAtPx17(item, px17)
        listing_lines = ListingService::decideListingLines(item)
        ListingService::insertUpdateEntryComponents1(item, px17, listing_lines)
    end

    # ------------------------------------------------------
    # Listing

    # ListingService::itemsForListing1()
    def self.itemsForListing1()
        items = [
            NxEvents::listingItems(),
            NxOpens::listingItems(),
            Anniversaries::listingItems(),
            Waves::listingItemsInterruption(),
            NxBackups::listingItems(),
            Items::mikuType("NxLine"),
            NxOnDates::listingItems(),
            NxDeadlines::listingItems(),
            NxProjects::listingItems(),
            Items::mikuType("NxTask"),
            Waves::nonInterruptionItemsForListing(),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # ListingService::entriesForListing(excludeuuids)
    def self.entriesForListing(excludeuuids)
        entries = ListingService::entries()
            .reject{|entry| excludeuuids.include?(entry["itemuuid"]) }
            .select{|entry| DoNotShowUntil::isVisible(entry["itemuuid"]) }
            .map{|entry|
                entry["position"] = ListingService::decidePositionForEntry(entry)
                entry
            }
            .sort_by{|entry| entry["position"] }
    end

    # ------------------------------------------------------
    # Operations

    # ListingService::ensure(item)
    def self.ensure(item)
        if ListingService::hasItem(item["uuid"]) then
            px17 = ListingService::getPx17(item["uuid"])
        else
            px17 = {
                "type" => "compute"
            }
        end
        ListingService::insertUpdateItemAtPx17(item, px17)
    end

    # ListingService::ensureAtFirstPositionForTheDay(item)
    def self.ensureAtFirstPositionForTheDay(item)
        px17 = {
            "type"  => "overriden",
            "value" => ListingService::firstPositionInDatabase()*0.9,
            "expiry"=> CommonUtils::unixtimeAtComingMidnightAtLocalTimezone()
        }
        ListingService::insertUpdateItemAtPx17(item, px17)
    end

    # ListingService::evaluate(itemuuid)
    def self.evaluate(itemuuid)
        item = Items::itemOrNull(itemuuid)
        if item.nil? then
            ListingService::removeEntry(itemuuid)
            return
        end
        if !ListingService::isListable(item) then
            ListingService::removeEntry(itemuuid)
            return
        end
        ListingService::ensure(item)
    end

    # ListingService::removeEntry(itemuuid)
    def self.removeEntry(itemuuid)
        filepath = ListingService::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [itemuuid])
        db.commit
        db.close
        ListingService::ensureContentAddressing(filepath)
    end

    # ListingService::maintenance()
    def self.maintenance()
        ListingService::entries().each{|entry|
            if !ListingService::isListable(entry["item"]) then
                ListingService::removeEntry(entry["itemuuid"])
            end
        }
        ListingService::itemsForListing1().each{|item|
            if ListingService::isListable(item) then
                ListingService::evaluate(item["uuid"])
            end
        }
        archive_filepath = "#{ListingService::directory()}/archives/#{CommonUtils::today()}.sqlite3"
        if !File.exist?(archive_filepath) then
            FileUtils.cp(ListingService::getDatabaseFilepath(), archive_filepath)
        end
    end
end
