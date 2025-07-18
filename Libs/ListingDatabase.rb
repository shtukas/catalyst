
# create table listing (itemuuid TEXT, position REAL);

class ListingDatabase

    # ------------------------------------------------------
    # Basic IO and setters

    # ListingDatabase::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/ListingDatabase"
    end

    # ListingDatabase::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(ListingDatabase::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
    end

    # ListingDatabase::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{ListingDatabase::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # ListingDatabase::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{ListingDatabase::directory()}/#{filename}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table listing (itemuuid TEXT, position REAL)", [])
        db.commit
        db.close
        ListingDatabase::ensureContentAddressing(filepath)
    end

    # ListingDatabase::extractDataFromFile(filepath)
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

    # ListingDatabase::getReducedDatabaseFilepath()
    def self.getReducedDatabaseFilepath()
        filepaths = ListingDatabase::filepaths()

        if filepaths.size == 0 then
            return ListingDatabase::initiateDatabaseFile()
        end

        if filepaths.size == 1 then
            return filepaths[0]
        end

        data = filepaths
            .map{|filepath|
                ListingDatabase::extractDataFromFile(filepath)
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
        newfilepath = ListingDatabase::initiateDatabaseFile()

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

        ListingDatabase::ensureContentAddressing(newfilepath)
    end

    # ListingDatabase::insertEntry(itemuuid, position)
    def self.insertEntry(itemuuid, position)
        filepath = ListingDatabase::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("insert into listing (itemuuid, position) values (?, ?)", [itemuuid, position])
        db.commit
        db.close
        ListingDatabase::ensureContentAddressing(filepath)
    end

    # ListingDatabase::removeEntry(itemuuid)
    def self.removeEntry(itemuuid)
        filepath = ListingDatabase::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from listing where itemuuid=?", [itemuuid])
        db.commit
        db.close
        ListingDatabase::ensureContentAddressing(filepath)
    end

    # ListingDatabase::setPosition(itemuuid, position)
    def self.setPosition(itemuuid, position)
        filepath = ListingDatabase::getReducedDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("update listing set position = ? where itemuuid = ?", [position, itemuuid])
        db.commit
        db.close
        ListingDatabase::ensureContentAddressing(filepath)
    end

    # ------------------------------------------------------
    # Data

    # ListingDatabase::getListingData()
    def self.getListingData()
        ListingDatabase::extractDataFromFile(ListingDatabase::getReducedDatabaseFilepath())
    end

    # ListingDatabase::firstPositionInDatabase()
    def self.firstPositionInDatabase()
        data = ListingDatabase::getListingData()
        return 1 if data.empty?
        data.map{|e| e["position"] }.min
    end

    # ListingDatabase::lastPositionInDatabase()
    def self.lastPositionInDatabase()
        data = ListingDatabase::getListingData()
        return 1 if data.empty?
        data.map{|e| e["position"] }.max
    end

    # ListingDatabase::itemsForListing()
    def self.itemsForListing()
        items = ListingDatabase::getListingData()
                .map{|entry|
                    item = Items::itemOrNull(entry["itemuuid"])
                    if item then
                        item["x-listing-position"] = entry["position"]
                        item
                    else
                        ListingDatabase::removeEntry(entry["itemuuid"])
                        nil
                    end
                }
                .compact
                .sort_by{|item| item["x-listing-position"] }
        CommonUtils::removeDuplicateObjectsOnAttribute(items, "uuid")
    end

    # ------------------------------------------------------
    # Operations

    # ListingDatabase::decidePosition(item)
    def self.decidePosition(item)
        if item["mikuType"] == "Wave" and item["interruption"] then
            return ListingDatabase::firstPositionInDatabase() * 0.9
        end
        first = ListingDatabase::firstPositionInDatabase()
        last  = ListingDatabase::lastPositionInDatabase()
        mid = 0.5*(first + last)
        mid + 0.2 * (last - mid) + rand * (last - mid)
    end

    # ListingDatabase::listingMaintenance()
    def self.listingMaintenance()
        data = ListingDatabase::getListingData()
        databaseuuids = data.map{|entry| entry["itemuuid"] }
        Listing::itemsForListing2()
            .select{|item| !databaseuuids.include?(item["uuid"]) }
            .each{|item|
                position = ListingDatabase::decidePosition(item)
                ListingDatabase::insertEntry(item["uuid"], position)
            }
    end
end
