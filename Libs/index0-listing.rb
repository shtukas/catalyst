
# create table listing (itemuuid TEXT, position REAL);

class Index0

    # ------------------------------------------------------
    # Basic IO and setters

    # Index0::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/ListingDatabase"
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
        db.execute("create table listing (itemuuid TEXT, position REAL)", [])
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
        db.execute("select * from listing", []) do |row|
            data << {
                "itemuuid" => row["itemuuid"],
                "position" => row["position"]
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
                Index0::extractDataFromFile(filepath)
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
            db.execute("insert into listing (itemuuid, position) values (?, ?)", [entry["itemuuid"], entry["position"]])
        }
        db.commit
        db.close

        filepaths.each{|filepath|
            FileUtils::rm(filepath)
        }

        Index0::ensureContentAddressing(newfilepath)
    end

    # Index0::insertEntry(itemuuid, position)
    def self.insertEntry(itemuuid, position)
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("insert into listing (itemuuid, position) values (?, ?)", [itemuuid, position])
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

    # Index0::setPosition(itemuuid, position)
    def self.setPosition(itemuuid, position)
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

    # ------------------------------------------------------
    # Data

    # Index0::getListingData()
    def self.getListingData()
        Index0::extractDataFromFile(Index0::getReducedDatabaseFilepath())
    end

    # Index0::firstPositionInDatabase()
    def self.firstPositionInDatabase()
        data = Index0::getListingData()
        return 1 if data.empty?
        data.map{|e| e["position"] }.min
    end

    # Index0::lastPositionInDatabase()
    def self.lastPositionInDatabase()
        data = Index0::getListingData()
        return 1 if data.empty?
        data.map{|e| e["position"] }.max
    end

    # Index0::itemsForListing()
    def self.itemsForListing()
        items = Index0::getListingData()
                .map{|entry|
                    item = Items::itemOrNull(entry["itemuuid"])
                    if item then
                        item["x-listing-position"] = entry["position"]
                        item
                    else
                        Index0::removeEntry(entry["itemuuid"])
                        nil
                    end
                }
                .compact
                .sort_by{|item| item["x-listing-position"] }
        CommonUtils::removeDuplicateObjectsOnAttribute(items, "uuid")
    end

    # Index0::hasItem(itemuuid)
    def self.hasItem(itemuuid)
        answer = false
        filepath = Index0::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index1 where itemuuid=?", [itemuuid]) do |row|
            answer = true
        end
        db.close
        answer
    end

    # ------------------------------------------------------
    # Operations

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

    # Index0::listingMaintenance()
    def self.listingMaintenance()
        Listing::itemsForListing1().each{|item|
            next if Index0::hasItem(item["uuid"])
            position = Index0::decidePosition(item)
            Index0::insertEntry(item["uuid"], position)
        }
    end
end
