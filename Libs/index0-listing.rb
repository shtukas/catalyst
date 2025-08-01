
=begin

CREATE TABLE listing (
    itemuuid TEXT NOT NULL,
    utime REAL NOT NULL,
    position REAL NOT NULL,
    item TEXT NOT NULL,
    line TEXT NOT NULL
);

itemuuid:
utime   : unixtime with decimals of the last update of that record
position:
item    :
line    :

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
        db.execute("CREATE TABLE listing (itemuuid TEXT NOT NULL, utime REAL NOT NULL, position REAL NOT NULL, item TEXT NOT NULL, line TEXT NOT NULL)", [])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # Index0::extractDataFromFileEntriesInOrder(filepath)
    def self.extractDataFromFileEntriesInOrder(filepath)
        data = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from listing order by position", []) do |row|
            item = JSON.parse(row["item"])
            position_ = " (#{row["position"]})"
            data << {
                "itemuuid" => row["itemuuid"],
                "utime"    => row["utime"],
                "position" => row["position"],
                "item"     => item,
                "line"     => row["line"]
            }
        end
        db.close
        data
    end

    # Index0::getReducedDatabaseFilepath()
    def self.getReducedDatabaseFilepath()
        filepaths = Index0::filepaths()

        if filepaths.size == 0 then
            return Index0::initiateDatabaseFile()
        end

        if filepaths.size == 1 then
            return filepaths[0]
        end

        data = filepaths
            .map{|filepath|
                Index0::extractDataFromFileEntriesInOrder(filepath)
            }
            .flatten
            .sort_by{|entry| entry["position"] }
            .reduce([]){|entries, entry|
                if entries.map{|e| e["itemuuid"] }.include?(entry["itemuuid"]) then
                    entries
                else
                    entries + [entry]
                end
            }

        # In this case filepath.size > 1
        newfilepath = Index0::initiateDatabaseFile()
        db = SQLite3::Database.new(newfilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        data.each{|entry|
            db.execute("insert into listing (itemuuid, utime, position, item, line) values (?, ?, ?, ?, ?)", [entry["itemuuid"], entry["utime"], entry["position"], JSON.generate(entry["item"]), entry["line"]])
        }
        db.commit
        db.close

        filepaths.each{|filepath|
            FileUtils::rm(filepath)
        }

        Index0::ensureContentAddressing(newfilepath)
    end

    # Index0::hasItem(itemuuid)
    def self.hasItem(itemuuid)
        answer = false
        filepath = Index0::getReducedDatabaseFilepath()
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
        filepath = Index0::getReducedDatabaseFilepath()
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

    # Index0::insertUpdateEntry(itemuuid, position, item, line)
    def self.insertUpdateEntry(itemuuid, position, item, line)
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [itemuuid])
        db.execute("insert into listing (itemuuid, utime, position, item, line) values (?, ?, ?, ?, ?)", [itemuuid, Time.new.to_f, position, JSON.generate(item), line])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # Index0::updatePosition(itemuuid, position)
    def self.updatePosition(itemuuid, position)
        return if !Index0::hasItem(itemuuid)
        filepath = Index0::getReducedDatabaseFilepath()
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
        filepath = Index0::getReducedDatabaseFilepath()
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
    end

    # Index0::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{Index0::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # ------------------------------------------------------
    # Getters

    # Index0::entriesInOrder()
    def self.entriesInOrder()
        Index0::extractDataFromFileEntriesInOrder(Index0::getReducedDatabaseFilepath())
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

    # Index0::decideLine(item)
    def self.decideLine(item)
        return nil if item.nil?
        hasChildren = Index2::hasChildren(item["uuid"]) ? " [children]".red : ""
        line = "STORE-PREFIX #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}#{hasChildren}"

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        line
    end

    # Index0::determinePositionInInterval(item, x0, x1)
    def self.determinePositionInInterval(item, x0, x1)
        entries = Index0::entriesInOrder()
        entries_similar_positions = entries.select{|e| e["item"]["mikuType"] == item["mikuType"] }.map{|e| e["position"] }
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
        # 0.26 NxAnniversary
        # 0.28 NxLambda
        # 0.30 Wave sticky
        # 0.32 Wave interruption
        # 0.35 NxLine
        # 0.39 NxFloat
        # 0.40 NxBackup
        # 0.45 NxDated
        # 0.50 NxProject
        # 0.60 Wave
        # 0.70 NxCore & NxTask
        # 0.80 Bottom

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
        line = Index0::decideLine(item)
        Index0::insertUpdateEntry(item["uuid"], position, item, line)
    end

    # Index0::evaluate(itemuuid)
    def self.evaluate(itemuuid)
        item = Items::itemOrNull(itemuuid)
        if item.nil? then
            Index0::removeEntry(itemuuid)
            return
        end
        if !Index0::isListable(item) then
            Index0::removeEntry(itemuuid)
            return
        end
        position = Index0::getExistingPositionOrDecideNew(item)
        line = Index0::decideLine(item)
        Index0::insertUpdateEntry(itemuuid, position, item, line)
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
            line = Index0::decideLine(item)
            Index0::insertUpdateEntry(item["uuid"], position, item, line)
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
