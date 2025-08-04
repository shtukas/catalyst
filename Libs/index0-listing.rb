
# alter table listing rename column line to listing_line;
# alter table listing add column mikuType TEXT NOT NULL default "";

=begin

CREATE TABLE random (value REAL);

CREATE TABLE listing (
    itemuuid TEXT PRIMARY KEY NOT NULL,
    utime REAL NOT NULL,
    item TEXT NOT NULL,
    mikuType TEXT NOT NULL,
    position REAL NOT NULL,
    listing_line TEXT NOT NULL
);

itemuuid     :
utime        : unixtime with decimals of the last update of that record
item         :
mikuType     :
position     :
listing_line :

=end

class Index0

    # ------------------------------------------------------
    # Only Database Manipulations

    # Index0::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{Index0::directory()}/#{filename}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        # Because we are doing content addressing we need the newly created database to be distinct that one that could already be there.
        db.execute("CREATE TABLE random (value REAL)", [])
        db.execute("insert into random (value) values (?)", [rand])
        db.execute("CREATE TABLE listing (itemuuid TEXT PRIMARY KEY NOT NULL, utime REAL NOT NULL, item TEXT NOT NULL, mikuType TEXT NOT NULL, position REAL NOT NULL, listing_line TEXT NOT NULL)", [])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # Index0::extractDataFromFile(filepath)
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
                "listing_line" => row["listing_line"]
            }
        end
        db.close
        data
    end

    # Index0::extractEntryOrNullFromFilepath(filepath, itemuuid)
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
                "listing_line" => row["listing_line"]
            }
        end
        db.close
        data
    end

    # Index0::insertUpdateEntryComponents2(filepath, utime, item, position, listing_line)
    def self.insertUpdateEntryComponents2(filepath, utime, item, position, listing_line)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [item["uuid"]])
        db.execute("insert into listing (itemuuid, utime, item, mikuType, position, listing_line) values (?, ?, ?, ?, ?, ?)", [item["uuid"], utime, JSON.generate(item), item["mikuType"], position, listing_line])
        db.commit
        db.close
    end

    # Index0::mergeTwoDatabaseFiles(filepath1, filepath2) # -> filepath of the 
    def self.mergeTwoDatabaseFiles(filepath1, filepath2)
        # The logic here is to read the items from filepath2 and 
        # possibly add them to filepath1, if either:
        #   - there was no equivalent in filepath1
        #   - it's a newer record than the one in filepath1
        Index0::extractDataFromFile(filepath2).each{|entry2|
            shouldInject = false
            entry1 = Index0::extractEntryOrNullFromFilepath(filepath1, entry2["item"]["uuid"])
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
                Index0::insertUpdateEntryComponents2(filepath1, entry2["utime"], entry2["item"], entry2["position"], entry2["listing_line"])
            end
        }
        # Then when we are done, we delete filepath2
        FileUtils::rm(filepath2)
        Index0::ensureContentAddressing(filepath1)
    end

    # Index0::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = Index0::filepaths()

        # This case should not really happen (anymore), so if the condition 
        # is true, let's error noisily.
        if filepaths.size == 0 then
            # return Index0::initiateDatabaseFile()
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
            filepath1 = Index0::mergeTwoDatabaseFiles(filepath1, filepath)
        }
        filepath1
    end

    # Index0::hasItem(itemuuid)
    def self.hasItem(itemuuid)
        answer = false
        filepath = Index0::getDatabaseFilepath()
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

    # Index0::getPositionOrNull(itemuuid)
    def self.getPositionOrNull(itemuuid)
        position = nil
        filepath = Index0::getDatabaseFilepath()
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

    # Index0::insertUpdateEntryComponents1(item, position, listing_line)
    def self.insertUpdateEntryComponents1(item, position, listing_line)
        filepath = Index0::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [item["uuid"]])
        db.execute("insert into listing (itemuuid, utime, position, item, listing_line) values (?, ?, ?, ?, ?)", [item["uuid"], Time.new.to_f, position, JSON.generate(item), listing_line])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # Index0::updatePosition(itemuuid, position)
    def self.updatePosition(itemuuid, position)
        return if !Index0::hasItem(itemuuid)
        filepath = Index0::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("update listing set position=?, utime=? where itemuuid=?", [position, Time.new.to_f, itemuuid])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # Index0::removeEntry(itemuuid)
    def self.removeEntry(itemuuid)
        filepath = Index0::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [itemuuid])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # ------------------------------------------------------
    # Basic IO management

    # Index0::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/indices/index0-listing"
    end

    # Index0::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Index0::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
            .sort
    end

    # Index0::ensureContentAddressing(filepath1)
    def self.ensureContentAddressing(filepath1)
        filename2 = "#{Digest::SHA1.file(filepath1).hexdigest}.sqlite3"
        filepath2 = "#{Index0::directory()}/#{filename2}"
        return filepath1 if filepath1 == filepath2
        FileUtils.mv(filepath1, filepath2)
        filepath2
    end

    # ------------------------------------------------------
    # Getters

    # Index0::entriesInOrder()
    def self.entriesInOrder()
        Index0::extractDataFromFile(Index0::getDatabaseFilepath())
            .sort_by{|item| item["position"] }
    end

    # Index0::firstPositionInDatabase()
    def self.firstPositionInDatabase()
        entries = Index0::entriesInOrder()
        return 1 if entries.empty?
        entries.map{|e| e["position"] }.min
    end

    # Index0::itemsForListing(excludeuuids)
    def self.itemsForListing(excludeuuids)
        Index0::entriesInOrder()
            .reject{|entry| excludeuuids.include?(entry["itemuuid"]) }
            .sort_by{|entry| entry["position"] }
    end

    # ------------------------------------------------------
    # Decisions

    # Index0::decideListingLine(item)
    def self.decideListingLine(item)
        return nil if item.nil?
        hasChildren = Index2::hasChildren(item["uuid"]) ? " [children]".red : ""
        listing_line = "STORE-PREFIX #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}#{hasChildren}"

        if TmpSkip1::isSkipped(item) then
            listing_line = listing_line.yellow
        end

        if NxBalls::itemIsActive(item) then
            listing_line = listing_line.green
        end

        listing_line
    end

    # Index0::determinePositionInInterval(item, x0, x1)
    def self.determinePositionInInterval(item, x0, x1)
        entries = Index0::entriesInOrder()
        entries_similar_positions = entries
            .select{|e| e["item"]["mikuType"] == item["mikuType"] }
            .select{|e| e["position"] >= x0 and e["position"] < x1 }
            .map{|e| e["position"] }
        if entries_similar_positions.empty? then
            return x0
        end
        0.5*( entries_similar_positions.max + x1 )
    end

    # Index0::isListable(item)
    def self.isListable(item)
        if item["mikuType"] == "NxLambda" then
            return true
        end

        if item["mikuType"] == "NxFloat" then
            return DoNotShowUntil::isVisible(item["uuid"])
        end

        if item["mikuType"] == "Wave" then
            return DoNotShowUntil::isVisible(item["uuid"])
        end

        if item["mikuType"] == "NxCore" then
            return NxCores::ratio(item) < 1
        end

        if item["mikuType"] == "NxTask" then
            return DoNotShowUntil::isVisible(item["uuid"])
        end

        if item["mikuType"] == "NxProject" then
            return true
        end

        if item["mikuType"] == "NxLine" then
            return DoNotShowUntil::isVisible(item["uuid"])
        end

        if item["mikuType"] == "NxDated" then
            return ((item["date"][0, 10] <= CommonUtils::today()) and DoNotShowUntil::isVisible(item["uuid"]))
        end

        if item["mikuType"] == "NxAnniversary" then
            return item["next_celebration"] <= CommonUtils::today()
        end

        if item["mikuType"] == "NxBackup" then
            return DoNotShowUntil::isVisible(item["uuid"])
        end

        if item["mikuType"] == "NxDeleted" then
            return false
        end

        puts "I do not know how to Index0::isListable(#{JSON.pretty_generate(item)})"
        raise "(error: 3ae9fe86)"
    end

    # Index0::decidePosition(item)
    def self.decidePosition(item)
        # We return null if the item shouild not be listed at this time, because it has 
        # reached a time target or something.

        # Manually positioned (example for sorting)
        # 0.00 -> 0.20

        # Natural Positions
        # 0.26 -> 0.28 NxAnniversary
        # 0.28 -> 0.30 NxLambda
        # 0.30 -> 0.32 Wave sticky
        # 0.32 -> 0.35 Wave interruption
        # 0.35 -> 0.39 NxLine
        # 0.39 -> 0.40 NxFloat
        # 0.40 -> 0.45 NxBackup
        # 0.45 -> 0.50 NxDated
        # 0.50 -> 0.60 NxProject
        # 0.60 -> 0.70 Wave
        # 0.70 -> 0.80 NxCore & NxTask
        # 0.80 -> 0.90 Not required but wonderful if done

        if item["mikuType"] == "NxLambda" then
            return Index0::determinePositionInInterval(item, 0.28, 0.30)
        end

        if item["mikuType"] == "NxFloat" then
            return Index0::determinePositionInInterval(item, 0.39, 0.40)
        end

        if item["mikuType"] == "Wave" then
            if item["interruption"]  then
                return Index0::determinePositionInInterval(item, 0.32, 0.35)
            end
            if item["nx46"]["type"] == "sticky" then
                return Index0::determinePositionInInterval(item, 0.30, 0.32)
            end
            return Index0::determinePositionInInterval(item, 0.60, 0.70)
        end

        if item["mikuType"] == "NxCore" then
            return Index0::determinePositionInInterval(item, 0.70, 0.80)
        end

        if item["mikuType"] == "NxTask" then
            return Index0::determinePositionInInterval(item, 0.70, 0.80)
        end

        if item["mikuType"] == "NxProject" then
            return Index0::determinePositionInInterval(item, 0.50, 0.60)
        end

        if item["mikuType"] == "NxLine" then
            return Index0::determinePositionInInterval(item, 0.35, 0.39)
        end

        if item["mikuType"] == "NxDated" then
            return Index0::determinePositionInInterval(item, 0.35, 0.50)
        end

        if item["mikuType"] == "NxAnniversary" then
            return Index0::determinePositionInInterval(item, 0.26, 0.28)
        end

        if item["mikuType"] == "NxBackup" then
            return Index0::determinePositionInInterval(item, 0.40, 0.45)
        end

        puts "I do not know how to Index0::decidePosition(#{JSON.pretty_generate(item)})"
        raise "(error: 3ae9fe86)"
    end

    # Index0::getExistingPositionOrDecideNew(item)
    def self.getExistingPositionOrDecideNew(item)
        existing = Index0::getPositionOrNull(item["uuid"])
        return existing if existing
        Index0::decidePosition(item)
    end

    # --------------------------------------------------
    # Setters and updaters

    # Index0::insertUpdateItemAtPosition(item, position)
    def self.insertUpdateItemAtPosition(item, position)
        listing_line = Index0::decideListingLine(item)
        Index0::insertUpdateEntryComponents1(item, position, listing_line)
    end

    # Index0::evaluate(itemuuid)
    def self.evaluate(itemuuid)
        item = Index3::itemOrNull(itemuuid)
        if item.nil? then
            Index0::removeEntry(itemuuid)
            return
        end
        if !Index0::isListable(item) then
            Index0::removeEntry(itemuuid)
            return
        end
        position = Index0::getExistingPositionOrDecideNew(item)
        listing_line = Index0::decideListingLine(item)
        Index0::insertUpdateEntryComponents1(item, position, listing_line)
    end

    # ------------------------------------------------------
    # Operations

    # Index0::listingMaintenance()
    def self.listingMaintenance()
        Listing::itemsForListing1().each{|item|
            position = Index0::getExistingPositionOrDecideNew(item)
            if position.nil? then
                raise "We should not have a position null from Index0::listingMaintenance(): #{item}"
            end
            listing_line = Index0::decideListingLine(item)
            Index0::insertUpdateEntryComponents1(item, position, listing_line)
        }

        # We are now going to try an create a condition: one waves between any non two wave items
        entries_wave = Index0::entriesInOrder().select{|entry| entry["item"]["mikuType"] == "Wave" }
        entries_all = Index0::entriesInOrder()
        loop {
            break if (entries_all.size < 2 or entries_wave.size == 0)
            if (entries_all[0]["mikuType"] != "Wave" and entries_all[1]["mikuType"] != "Wave") then
                entry_wave = entries_wave.shift
                position = 0.5*(entries_all[0]["position"] + entries_all[1]["position"])
                Index0::updatePosition(entry_wave["itemuuid"], position)
            end
            entries_all.shift
        }
    end
end
