
# alter table listing rename column line to listing_lines;
# alter table listing add column mikuType TEXT NOT NULL default "";

=begin

CREATE TABLE random (value REAL);
CREATE TABLE listing (
    itemuuid TEXT PRIMARY KEY NOT NULL,
    utime REAL NOT NULL,
    item TEXT NOT NULL,
    mikuType TEXT NOT NULL,
    position REAL NOT NULL,
    position_type TEXT,
    listing_lines TEXT NOT NULL
);

itemuuid      : string
utime         : unixtime with decimals of the last update of that record
item          : json encoded object
mikuType      : string
position      : float
position_type : string
listing_lines : json encoded array

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
        db.execute("CREATE TABLE listing (itemuuid TEXT PRIMARY KEY NOT NULL, utime REAL NOT NULL, item TEXT NOT NULL, mikuType TEXT NOT NULL, position REAL NOT NULL, position_type TEXT, listing_lines TEXT NOT NULL)", [])
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
                ListingService::insertUpdateEntryComponents2(filepath1, entry2["utime"], entry2["item"], entry2["position"], entry2["position_type"], entry2["listing_lines"])
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

    # ListingService::insertUpdateEntryComponents2(filepath, utime, item, position, position_type, listing_lines)
    def self.insertUpdateEntryComponents2(filepath, utime, item, position, position_type, listing_lines)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [item["uuid"]])
        db.execute("insert into listing (itemuuid, utime, item, mikuType, position, position_type, listing_lines) values (?, ?, ?, ?, ?, ?, ?)", [item["uuid"], utime, JSON.generate(item), item["mikuType"], position, position_type, JSON.generate(listing_lines)])
        db.commit
        db.close
    end

    # ListingService::insertUpdateEntryComponents1(item, position, position_type, listing_lines)
    def self.insertUpdateEntryComponents1(item, position, position_type, listing_lines)
        filepath = ListingService::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [item["uuid"]])
        db.execute("insert into listing (itemuuid, utime, item, mikuType, position, position_type, listing_lines) values (?, ?, ?, ?, ?, ?, ?)", [item["uuid"], Time.new.to_f, JSON.generate(item), item["mikuType"], position, position_type, JSON.generate(listing_lines)])
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
        db.execute("select * from listing order by position", []) do |row|
            data << {
                "itemuuid" => row["itemuuid"],
                "utime"    => row["utime"],
                "item"     => JSON.parse(row["item"]),
                "mikuType" => row["mikuType"],
                "position" => row["position"],
                "position_type" => row["position_type"],
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
                "position" => row["position"],
                "position_type" => row["position_type"],
                "listing_lines" => JSON.parse(row["listing_lines"])
            }
        end
        db.close
        data
    end

    # ------------------------------------------------------
    # Data

    # ListingService::criticals()
    def self.criticals()
        Items::items()
            .select{|item| item["critical-0825"] }
    end

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

    # ListingService::getPosition(itemuuid)
    def self.getPosition(itemuuid)
        position = nil
        filepath = ListingService::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from listing where itemuuid=?", [itemuuid]) do |row|
            position = row["position"]
        end
        db.close
        if position.nil? then
            raise "(error: d330c4f1)"
        end
        position
    end

    # ListingService::getPositionOrNull(itemuuid)
    def self.getPositionOrNull(itemuuid)
        position = nil
        filepath = ListingService::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from listing where itemuuid=?", [itemuuid]) do |row|
            position = row["position"]
        end
        db.close
        position
    end

    # ListingService::getPositionType(itemuuid)
    def self.getPositionType(itemuuid)
        position_type = nil
        filepath = ListingService::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from listing where itemuuid=?", [itemuuid]) do |row|
            position_type = row["position_type"]
        end
        db.close
        if position_type.nil? then
            raise "(error: 41114599)"
        end
        position_type
    end

    # ListingService::getPositionTypeOrNull(itemuuid)
    def self.getPositionTypeOrNull(itemuuid)
        position_type = nil
        filepath = ListingService::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from listing where itemuuid=?", [itemuuid]) do |row|
            position_type = row["position_type"]
        end
        db.close
        position_type
    end

    # ListingService::decideListingLines(item)
    def self.decideListingLines(item)
        return [] if item.nil?
        lines = []
        hasChildren = Parenting::hasChildren(item["uuid"]) ? " [children]".red : ""
        line = "STORE-PREFIX #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}#{hasChildren}"

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

    # ListingService::determinePositionInInterval(item, x0, x1)
    def self.determinePositionInInterval(item, x0, x1)
        entries = ListingService::entries()
        entries_similar_positions = entries
            .select{|e| e["item"]["uuid"] != item["uuid"] }
            .select{|e| e["item"]["mikuType"] == item["mikuType"] }
            .select{|e| e["position"] >= x0 and e["position"] < x1 }
            .map{|e| e["position"] }
        if entries_similar_positions.empty? then
            return x0
        end
        0.5*( entries_similar_positions.max + x1 )
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

        if item["mikuType"] == "NxLine" then
            return true
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

    # ListingService::decidePosition(item)
    def self.decidePosition(item)
        # We return null if the item shouild not be listed at this time, because it has 
        # reached a time target or something.

        # Manually positioned (example for sorting)
        # 0.00 -> 0.20

        # NxLines do not have a natural position, they have the position that
        # had when created or when they were repositioned due to sorting.
        # They are essentially only created for priority items, with the
        # exception of Desktop/Dispatch/Line-Stream, which are put at 0.21.

        # Natural Positions
        # 0.26 -> 0.28 NxAnniversary
        # 0.28 -> 0.30 NxLambda
        # 0.30 -> 0.32 Wave sticky
        # 0.32 -> 0.35 Wave interruption
        # 0.37 -> 0.37 criticals
        # 0.39 -> 0.40 NxFloat
        # 0.40 -> 0.45 NxBackup

        # 0.48         NxTask Orphan

        # 0.50 -> 0.80 Dynamic positioning of
        #              NxDated
        #              Wave
        #              NxCore & NxTask

        # 0.80 -> 0.90 Not required but wonderful if done

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

        if item["mikuType"] == "NxLine" then
            return ListingService::getPositionOrNull(item["uuid"]) || 0.21
        end

        if item["mikuType"] == "NxAnniversary" then
            return ListingService::determinePositionInInterval(item, 0.26, 0.28)
        end

        if item["mikuType"] == "NxBackup" then
            return ListingService::determinePositionInInterval(item, 0.40, 0.45)
        end

        if item["mikuType"] == "NxDated" then
            return 0.60 # Default positioning in 0.50 -> 0.80
                        # Will be dynamically computed by ListingService::entriesForListing
        end

        if item["mikuType"] == "Wave" then
            return 0.60 # Default positioning in 0.50 -> 0.80
                        # Will be dynamically computed by ListingService::entriesForListing
        end

        if item["mikuType"] == "NxCore" then
            return 0.60 # Default positioning in 0.50 -> 0.80
                        # Will be dynamically computed by ListingService::entriesForListing
        end

        if item["mikuType"] == "NxTask" then
            return 0.60 # Default positioning in 0.50 -> 0.80
                        # Will be dynamically computed by ListingService::entriesForListing
        end

        puts "I do not know how to ListingService::decidePosition(#{JSON.pretty_generate(item)})"
        raise "(error: 3ae9fe86)"
    end

    # ListingService::getExistingPositionOrDecideNew(item)
    def self.getExistingPositionOrDecideNew(item)
        existing = ListingService::getPositionOrNull(item["uuid"])
        return existing if existing
        ListingService::decidePosition(item)
    end

    # ListingService::entries()
    def self.entries()
        ListingService::extractDataFromFile(ListingService::getDatabaseFilepath())
            .sort_by{|entry| entry["position"] }
    end

    # ListingService::firstPositionInDatabase()
    def self.firstPositionInDatabase()
        entries = ListingService::entries()
        return 1 if entries.empty?
        entries.map{|entry| entry["position"] }.min
    end

    # ListingService::entriesForListing(excludeuuids)
    def self.entriesForListing(excludeuuids)

        # This is the source of this mapping, implemented in PolyFunctions::itemToBankingAccounts
        # NxDated         6a114b28-d6f2-4e92-9364-fadb3edc1122
        # Wave            e0d8f86a-1783-4eb7-8f63-11562d8972a2 (non interruption)
        # NxCore & NxTask 69297ca5-d92e-4a73-82cc-1d009e63f4fe

        # 0.50 -> 0.80 Dynamic positioning of
        #              NxDated
        #              Wave (non interruption)
        #              NxCore & NxTask

        isDynamicallyPositioned = lambda {|entry|
            return false if entry["position_type"] == "override"
            return true if ["NxDated", "NxCore", "NxTask"].include?(entry["mikuType"])
            return true if (entry["mikuType"] == "Wave" and !entry["item"]["interruption"])
            false
        }

        prepareNxDateds = lambda{|entries|
            entries.sort_by{|entry| entry["item"]["date"] }
        }

        prepareWaves = lambda{|entries|
            entries.sort_by{|entry| entry["item"]["lastDoneUnixtime"] }
        }

        prepareNxCoreNxTasks = lambda{|entries|
            lookUpRatio = lambda {|item|
                if item["mikuType"] == "NxTask" then
                    parent = Parenting::parentOrNull(item["uuid"])
                    if parent["mikuType"] == "NxCore" then
                        return NxCores::ratio(parent)
                    end
                    return 0
                end
                if item["mikuType"] == "NxCore" then
                    return NxCores::ratio(item)
                end
            }
            entries.sort_by{|entry| lookUpRatio.call(entry["item"]) }
        }

        entries = ListingService::entries()
            .reject{|entry| excludeuuids.include?(entry["itemuuid"]) }
            .select{|entry| DoNotShowUntil::isVisible(entry["itemuuid"]) }

        criticals = ListingService::criticals()
                        .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                        .map{|item|
                            {
                                "itemuuid" => item["uuid"],
                                "utime"    => 0,
                                "item"     => item,
                                "mikuType" => item["mikuType"],
                                "position" => 0.36,
                                "position_type" => "override",
                                "listing_lines" => ListingService::decideListingLines(item)
                            }
                        }

        dynamically_positioned, statically_positioned = entries.partition{|entry| isDynamicallyPositioned.call(entry) }

        d2 = [
            {
                "entries" => prepareNxDateds.call(dynamically_positioned.select{|entry| entry["mikuType"] == "NxDated" }),
                "rt" => BankData::recoveredAverageHoursPerDay("6a114b28-d6f2-4e92-9364-fadb3edc1122")
            },
            {
                "entries" => prepareWaves.call(dynamically_positioned.select{|entry| entry["mikuType"] == "Wave" }),
                "rt" => BankData::recoveredAverageHoursPerDay("e0d8f86a-1783-4eb7-8f63-11562d8972a2")
            },
            {
                "entries" => prepareNxCoreNxTasks.call(dynamically_positioned.select{|entry| entry["mikuType"] == "NxCore" or entry["mikuType"] == "NxTask" }),
                "rt" => BankData::recoveredAverageHoursPerDay("69297ca5-d92e-4a73-82cc-1d009e63f4fe")
            }
        ].sort_by{|packet| packet["rt"] }
         .map{|packet| packet["entries"] }
         .flatten
         .map{|entry|
            entry["position"] = nil
            entry
         }

        # The following works because every statically_positioned comes before any 
        # dynamically positioned, regarless of their respective orderings
        [
            (criticals + statically_positioned).sort_by{|entry| entry["position"] },
            d2
        ].flatten
    end

    # ------------------------------------------------------
    # Setters

    # ListingService::setPosition(itemuuid, position, position_type)
    def self.setPosition(itemuuid, position, position_type)
        return if !ListingService::hasItem(itemuuid)
        filepath = ListingService::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("update listing set position=?, position_type=?, utime=? where itemuuid=?", [position, position_type, Time.new.to_f, itemuuid])
        db.commit
        db.close
        ListingService::ensureContentAddressing(filepath)
    end

    # ListingService::insertUpdateItemAtPosition(item, position, position_type)
    def self.insertUpdateItemAtPosition(item, position, position_type)
        listing_lines = ListingService::decideListingLines(item)
        ListingService::insertUpdateEntryComponents1(item, position, position_type, listing_lines)
    end

    # ------------------------------------------------------
    # Operations

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

    # ListingService::ensure(item)
    def self.ensure(item)
        if ListingService::hasItem(item["uuid"]) then
            position = ListingService::getPosition(item["uuid"])
            position_type = ListingService::getPositionType(item["uuid"])
        else
            position = ListingService::decidePosition(item)
            position_type = "standard"
        end
        ListingService::insertUpdateItemAtPosition(item, position, position_type)
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

    # ListingService::maintenance()
    def self.maintenance()
        ListingService::entries().each{|entry|
            if !ListingService::isListable(entry["item"]) then
                ListingService::removeEntry(entry["itemuuid"])
            end
        }
        FrontPage::itemsForListing1().each{|item|
            if ListingService::isListable(item) then
                ListingService::evaluate(item["uuid"])
            end
        }
        NxTasks::orphan().each{|item|
            ListingService::insertUpdateItemAtPosition(item, 0.48, "override")
        }
        archive_filepath = "#{ListingService::directory()}/archives/#{CommonUtils::today()}.sqlite3"
        if !File.exist?(archive_filepath) then
            FileUtils.cp(ListingService::getDatabaseFilepath(), archive_filepath)
        end
    end
end
