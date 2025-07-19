
# create table listing (itemuuid TEXT NOT NULL, position REAL NOT NULL, item TEXT NOT NULL, line TEXT NOT NULL);

class Index0

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

    # Index0::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{Index0::directory()}/#{filename}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table listing (itemuuid TEXT NOT NULL, position REAL NOT NULL, item TEXT NOT NULL, line TEXT NOT NULL)", [])
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
            data << {
                "itemuuid" => row["itemuuid"],
                "position" => row["position"],
                "item"     => JSON.parse(row["item"]),
                "line"     => row["line"],
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
            db.execute("insert into listing (itemuuid, position, item, line) values (?, ?, ?, ?)", [entry["itemuuid"], entry["position"], entry["item"], entry["line"]])
        }
        db.commit
        db.close

        filepaths.each{|filepath|
            FileUtils::rm(filepath)
        }

        Index0::ensureContentAddressing(newfilepath)
    end

    # --------------------------------------------------
    # setters and updates

    # Index0::insertEntry(itemuuid, position, item, line)
    def self.insertEntry(itemuuid, position, item, line)
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [itemuuid])
        db.execute("insert into listing (itemuuid, position, item, line) values (?, ?, ?, ?)", [itemuuid, position, JSON.generate(item), line])
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

    # Index0::updatePosition(itemuuid, position)
    def self.updatePosition(itemuuid, position)
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("update listing set position = ? where itemuuid = ?", [position, itemuuid])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # Index0::updateItemsAndLine(itemuuid, item, line)
    def self.updateItemsAndLine(itemuuid, item, line)
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("update listing set item=?, line=? where itemuuid=?", [JSON.generate(item), line, itemuuid])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # ------------------------------------------------------
    # Data

    # Index0::getListingDataEntriesInOrder()
    def self.getListingDataEntriesInOrder()
        Index0::extractDataFromFileEntriesInOrder(Index0::getReducedDatabaseFilepath())
    end

    # Index0::firstPositionInDatabase()
    def self.firstPositionInDatabase()
        data = Index0::getListingDataEntriesInOrder()
        return 1 if data.empty?
        data.map{|e| e["position"] }.min
    end

    # Index0::lastPositionInDatabase()
    def self.lastPositionInDatabase()
        data = Index0::getListingDataEntriesInOrder()
        return 1 if data.empty?
        themax = data.map{|e| e["position"] }.max
        return (themax + 1) if data.size == 1 # this is to prevent first and last to have the same value
        themax
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

    # ------------------------------------------------------
    # Decisions

    # Index0::decidePosition(item)
    def self.decidePosition(item)
        if item["mikuType"] == "Wave" and item["interruption"] then
            return Index0::firstPositionInDatabase() * 0.9
        end
        if item["mikuType"] == "NxTask" and item["nx2290-important"] then
            first = Index0::firstPositionInDatabase()
            last  = Index0::lastPositionInDatabase()
            width = last-first
            return first + rand*0.25*width
        end
        first = Index0::firstPositionInDatabase()
        last  = Index0::lastPositionInDatabase()
        mid = 0.5*(first + last)
        mid + 0.2*(last - mid) + rand*(last - mid)
    end

    # Index0::decideLine(item, position)
    def self.decideLine(item, position)
        return nil if item.nil?
        hasChildren = Index2::hasChildren(item["uuid"]) ? " [children]".red : ""
        impt = item["nx2290-important"] ? " [important]".red : ""
        position_ = " (#{position})".yellow
        line = "STORE-PREFIX #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}#{impt}#{hasChildren}#{position_}"

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        line
    end

    # ------------------------------------------------------
    # Operations

    # Index0::compressPositions()
    def self.compressPositions()
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("update listing set position = position/2", [])
        db.commit
        db.close
        Index0::ensureContentAddressing(filepath)
    end

    # Index0::listingMaintenance()
    def self.listingMaintenance()
        if Index0::firstPositionInDatabase() >= 1 or Index0::lastPositionInDatabase() >= 100 then
            Index0::compressPositions()
        end
        Listing::itemsForListing1().each{|item|
            if Index0::hasItem(item["uuid"]) then
                position = Index0::getPositionOrNull(item["uuid"])
                # position is not going to be null because it comes from the database
                line = Index0::decideLine(item, position)
                Index0::updateItemsAndLine(item["uuid"], item, line)
            else
                position = Index0::decidePosition(item)
                line = Index0::decideLine(item, position)
                Index0::insertEntry(item["uuid"], position, item, line)
            end
        }
    end
end
