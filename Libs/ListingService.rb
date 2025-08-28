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
        parentingSuffix = Parenting::suffix(item)
        if item["mikuType"] == "NxTask" then
            parentingSuffix = ""
        end
        hasChildren = Parenting::hasChildren(item["uuid"]) ? " [children]".red : ""
        line = "STORE-PREFIX #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{Donations::donationSuffix(item)}#{parentingSuffix}#{DoNotShowUntil::suffix2(item)}#{hasChildren}"

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
        if item["mikuType"] == "NxLambda" then
            return true
        end

        if item["mikuType"] == "NxFloat" then
            return true
        end

        if item["mikuType"] == "Wave" then
            return true
        end

        if item["mikuType"] == "NxCore" then
            return NxCores::ratio(item) < 1
        end

        if item["mikuType"] == "NxTask" then
            return false if !DoNotShowUntil::isVisible(item["uuid"])
            parent = Parenting::parentOrNull(item["uuid"])
            return true if parent.nil?
            return NxCores::listingItems().map{|i| i["uuid"] }.include?(item["uuid"])
        end

        if item["mikuType"] == "NxDated" then
            return item["date"][0, 10] <= CommonUtils::today()
        end

        if item["mikuType"] == "NxAnniversary" then
            return item["next_celebration"] <= CommonUtils::today()
        end

        if item["mikuType"] == "NxBackup" then
            return true
        end

        if item["mikuType"] == "NxDeleted" then
            return false
        end

        puts "I do not know how to ListingService::isListable(#{JSON.pretty_generate(item)})"
        raise "(error: 3ae9fe86)"
    end

    # ListingService::determinePositionInInterval(item, x0, x1)
    def self.determinePositionInInterval(item, x0, x1)
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

    # ListingService::itemTo01(item)
    def self.itemTo01(item)
        if item["mikuType"] == "NxTask" then
            parent = Parenting::parentOrNull(item["uuid"])
            if parent and parent["mikuType"] == "NxCore" then
                return NxCores::ratio(parent) - ListingService::realLineTo01Decreasing(Parenting::childPositionAtParentOrZero(parent["uuid"], item["uuid"])).to_f/1000
            end
            return 0
        end
        if item["mikuType"] == "NxCore" then
            return NxCores::ratio(item)
        end
        if item["mikuType"] == "NxDated" then
            return ListingService::realLineTo01Increasing(item["position-0836"] || 0)
        end
        if item["mikuType"] == "Wave" then
            timeSinceLastDone = Time.new.to_i - item['lastDoneUnixtime']
            return ListingService::realLineTo01Increasing(-timeSinceLastDone)
        end
        raise "(error: e9f93758)"
    end

    # ListingService::itemToComputedPosition(item)
    def self.itemToComputedPosition(item)
        # We return null if the item shouild not be listed at this time, because it has 
        # reached a time target or something.

        # Manually positioned
        # 0.00 -> 0.20

        # Natural Positions
        # 0.260 -> 0.280 NxAnniversary
        # 0.280 -> 0.300 NxLambda
        # 0.300 -> 0.320 Wave sticky
        # 0.320 -> 0.350 Wave interruption
        # 0.390 -> 0.400 NxFloat
        # 0.400 -> 0.450 NxBackup

        # 0.48         NxTask Orphan (mostly former priority items, who survived overnight)

        # 0.50 -> 0.60 NxDated
        # 0.60 -> 0.70 Wave (non interruption)
        # 0.80 -> 0.90 NxCore & NxTask

        if item["mikuType"] == "NxLambda" then
            return ListingService::determinePositionInInterval(item, 0.28, 0.30)
        end

        if item["mikuType"] == "NxFloat" then
            return ListingService::determinePositionInInterval(item, 0.39, 0.40)
        end

        if item["mikuType"] == "Wave" then
            if item["interruption"] then
                return ListingService::determinePositionInInterval(item, 0.32, 0.35)
            end
            if item["nx46"]["type"] == "sticky" then
                return ListingService::determinePositionInInterval(item, 0.30, 0.32)
            end
        end

        if item["mikuType"] == "NxAnniversary" then
            return ListingService::determinePositionInInterval(item, 0.26, 0.28)
        end

        if item["mikuType"] == "NxBackup" then
            return ListingService::determinePositionInInterval(item, 0.40, 0.45)
        end

        if item["mikuType"] == "NxDated" then
            return 0.51 + ListingService::itemTo01(item).to_f/1000
        end

        if item["mikuType"] == "Wave" then
            return 0.61 + ListingService::itemTo01(item).to_f/1000
        end

        if item["mikuType"] == "NxTask" then
            return 0.81 + ListingService::itemTo01(item).to_f/1000
        end

        if item["mikuType"] == "NxCore" then
            return 0.81 + ListingService::itemTo01(item).to_f/1000
        end

        puts "I do not know how to ListingService::itemToComputedPosition(#{JSON.pretty_generate(item)})"
        raise "(error: df253fc4)"
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

    # ListingService::decidePositionForEntry(entry)
    def self.decidePositionForEntry(entry)
        px17 = entry["px17"]
        if px17["type"] == "compute" then
            return ListingService::itemToComputedPosition(entry["item"])
        end
        if px17["type"] == "overriden" then
            if Time.new.to_i < px17["expiry"] then
                return px17["value"]
            else
                return ListingService::itemToComputedPosition(entry["item"])
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
            Anniversaries::listingItems(),
            Waves::listingItemsInterruption(),
            NxBackups::listingItems(),
            NxDateds::listingItemsInOrder(),
            NxFloats::listingItems(),
            Waves::nonInterruptionItemsForListing(),
            NxCores::listingItems()
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
        NxTasks::orphan().each{|item|
            px17 = {
                "type"  => "overriden",
                "value" => 0.48,
                "expiry"=> CommonUtils::unixtimeAtComingMidnightAtLocalTimezone()
            }
            ListingService::insertUpdateItemAtPx17(item, px17)
        }
        archive_filepath = "#{ListingService::directory()}/archives/#{CommonUtils::today()}.sqlite3"
        if !File.exist?(archive_filepath) then
            FileUtils.cp(ListingService::getDatabaseFilepath(), archive_filepath)
        end
    end
end
