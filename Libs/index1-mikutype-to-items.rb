
# create table index1 (mikuType TEXT NOT NULL, itemuuid TEXT NOT NULL);

class Index1

    # ------------------------------------------------------
    # Basic IO management

    # Index1::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/indices/index1-mikuType-to-items"
    end

    # Index1::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Index1::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
    end

    # Index1::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{Index1::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # Index1::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{Index1::directory()}/#{filename}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table index1 (mikuType TEXT NOT NULL, itemuuid TEXT NOT NULL)", [])
        db.commit
        db.close
        Index1::ensureContentAddressing(filepath)
    end

    # Index1::extractDataFromFile(filepath)
    def self.extractDataFromFile(filepath)
        data = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index1", []) do |row|
            data << {
                "mikuType" => row["mikuType"],
                "itemuuid" => row["itemuuid"]
            }
        end
        db.close
        data
    end

    # Index1::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = Index1::filepaths()

        if filepaths.size == 0 then
            Index1::initiateDatabaseFile()
            Index1::maintenance()
            return Index1::getDatabaseFilepath()
        end

        if filepaths.size == 1 then
            return filepaths[0]
        end

        data = filepaths
            .map{|filepath|
                Index1::extractDataFromFile(filepath)
            }
            .flatten
            .map{|entry| "#{entry["mikuType"]}^#{entry["itemuuid"]}" }
            .uniq
            .map{|str|
                tokens = str.split("^")
                {
                    "mikuType" => tokens[0],
                    "itemuuid" => tokens[1]
                }
            }

        # In this case filepath.size > 1
        newfilepath = Index1::initiateDatabaseFile()

        db = SQLite3::Database.new(newfilepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        data.each{|entry|
            db.execute("insert into index1 (mikuType, itemuuid) values (?, ?)", [entry["mikuType"], entry["itemuuid"]])
        }
        db.commit
        db.close

        filepaths.each{|filepath|
            FileUtils::rm(filepath)
        }

        Index1::ensureContentAddressing(newfilepath)
    end

    # Index1::hasEntry(mikuType, itemuuid)
    def self.hasEntry(mikuType, itemuuid)
        answer = false
        filepath = Index1::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index1 where mikuType=? and itemuuid=?", [mikuType, itemuuid]) do |row|
            answer = true
        end
        db.close
        answer
    end

    # Index1::insertEntry(mikuType, itemuuid)
    def self.insertEntry(mikuType, itemuuid)
        filepath = Index1::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from index1 where mikuType=? and itemuuid=?", [mikuType, itemuuid])
        db.execute("insert into index1 (mikuType, itemuuid) values (?, ?)", [mikuType, itemuuid])
        db.commit
        db.close
        Index1::ensureContentAddressing(filepath)
    end

    # Index1::removeEntry(mikuType, itemuuid)
    def self.removeEntry(mikuType, itemuuid)
        filepath = Index1::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from index1 where mikuType=? and itemuuid=?", [mikuType, itemuuid])
        db.commit
        db.close
        Index1::ensureContentAddressing(filepath)
    end

    # Index1::removeItem(itemuuid)
    def self.removeItem(itemuuid)
        filepath = Index1::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from index1 where itemuuid=?", [itemuuid])
        db.commit
        db.close
        Index1::ensureContentAddressing(filepath)
    end

    # ------------------------------------------------------
    # Data

    # Index1::mikuTypeItemuuids(mikuType)
    def self.mikuTypeItemuuids(mikuType)
        Index1::extractDataFromFile(Index1::getDatabaseFilepath())
            .select{|entry| entry["mikuType"] == mikuType }
            .map{|entry| entry["itemuuid"] }
            .uniq
    end

    # Index1::mikuTypeItems(mikuType)
    def self.mikuTypeItems(mikuType)
        items = []
        Index1::mikuTypeItemuuids(mikuType)
        .each{|itemuuid|
            item = Index3::itemOrNull(itemuuid)
            if item.nil? then
                Index1::removeEntry(mikuType, itemuuid)
                next
            end
            if item["mikuType"] != mikuType then
                Index1::removeEntry(mikuType, itemuuid)
                next
            end
            items << item
        }
        items
    end

    # Index1::mikutypes()
    def self.mikutypes()
        Index1::extractDataFromFile(Index1::getDatabaseFilepath())
            .map{|entry| entry["mikuType"] }
            .uniq
    end

    # ------------------------------------------------------
    # Maintenance

    # Index1::maintenance()
    def self.maintenance()
        Index3::items().each{|item|
            next if Index1::hasEntry(item["mikuType"], item["uuid"])
            Index1::insertEntry(item["mikuType"], item["uuid"])
        }
    end
end
