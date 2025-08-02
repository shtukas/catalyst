
=begin
create table index3 (
    uuid text non null primary key,
    utime real non null,
    item text non null,
    mikyType text non null,
    description text non null
);
CREATE INDEX index1 ON index3(uuid, mikyType);
=end

class Index3

    # ------------------------------------------------------
    # Basic IO management

    # Index3::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/indices/index3-items"
    end

    # Index3::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Index3::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
    end

    # Index3::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{Index3::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # Index3::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{Index3::directory()}/#{filename}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table items (
            uuid text non null primary key,
            utime real non null,
            item text non null,
            mikyType text non null,
            description text non null
        )", [])
        db.execute("CREATE INDEX items_index ON items(uuid, mikyType);", [])
        db.commit
        db.close
        Index3::ensureContentAddressing(filepath)
    end

    # Index3::insertUpdateItemAtFile(filepath, item)
    def self.insertUpdateItemAtFile(filepath, item)
        uuid = item["uuid"]
        utime = Time.new.to_f
        mikyType = item["mikuType"]
        description = decideDescription(item)

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from items where uuid=?", [uuid])
        db.execute("insert into items (uuid, utime, item, mikyType, description) values (?, ?, ?, ?, ?)", [uuid, utime, JSON.generate(item), mikyType, description])
        db.commit
        db.close
        Index3::ensureContentAddressing(filepath)
    end

    # Index3::extractEntryOrNullFromFilepath(filepath, uuid)
    def self.extractEntryOrNullFromFilepath(filepath, uuid)
        entry = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from items where uuid=?", [uuid]) do |row|
            item = JSON.parse(row["item"])
            entry = {
                "uuid"        => row["uuid"],
                "utime"       => row["utime"],
                "item"        => JSON.parse(row["item"]),
                "mikuType"    => row["mikuType"],
                "description" => row["description"]
            }
        end
        db.close
        entry
    end

    # Index3::insertUpdateEntryComponents2(filepath, utime, item, mikuType, description)
    def self.insertUpdateEntryComponents2(filepath, utime, item, mikuType, description)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from items where uuid=?", [item["uuid"]])
        db.execute("insert into items (uuid, utime, item, mikuType, description) values (?, ?, ?, ?, ?)", [item["uuid"], utime, JSON.generate(item), mikuType, description])
        db.commit
        db.close
    end

    # Index3::mergeTwoDatabaseFiles(filepath1, filepath2) # -> filepath of the 
    def self.mergeTwoDatabaseFiles(filepath1, filepath2)
        # The logic here is to read the items from filepath2 and 
        # possibly add them to filepath1, if either:
        #   - there was no equivalent in filepath1
        #   - it's a newer record than the one in filepath1
        Index3::extractEntriesFromFile(filepath2).each{|entry2|
            shouldInject = false
            entry1 = Index3::extractEntryOrNullFromFilepath(filepath1, entry2["item"]["uuid"])
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
                Index3::insertUpdateEntryComponents2(filepath1, entry2["utime"], entry2["item"], entry2["mikuType"], entry2["description"])
            end
        }
        # Then when we are done, we delete filepath2
        FileUtils::rm(filepath2)
        Index3::ensureContentAddressing(filepath1)
    end

    # Index3::extractEntriesFromFile(filepath)
    def self.extractEntriesFromFile(filepath)
        entries = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from items", []) do |row|
            entries << {
                "uuid"        => row["uuid"],
                "utime"       => row["utime"],
                "item"        => JSON.parse(row["item"]),
                "mikuType"    => row["mikuType"],
                "description" => row["description"]
            }
        end
        db.close
        entries
    end

    # Index3::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = Index3::filepaths()

        # This case should not really happen (anymore), so if the condition 
        # is true, let's error noisily.
        if filepaths.size == 0 then
            # return Index3::initiateDatabaseFile()
            raise "(error: 739bcc7d)"
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

    # Index3::entryOrNull(uuid)
    def self.entryOrNull(uuid)
        Index3::filepaths().each{|filepath|
            entry = Index3::extractEntryOrNullFromFilepath(filepath, uuid)
            return entry if entry
        }
        nil
    end

    # Index3::deleteEntry(uuid)
    def self.deleteEntry(uuid)
        filepath = Index3::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from items where uuid=?", [uuid])
        db.commit
        db.close
        Index3::ensureContentAddressing(filepath)
    end

    # ------------------------------------------------------
    # Support

    # Index3::decideDescription(item)
    def self.decideDescription(item)
        return item["description"] if item["description"]
        raise "(error: d9a4a31c) I do not know how to determine the description for item: #{item}"
    end

    # ------------------------------------------------------
    # Interface

    # Index3::itemOrNull(item)
    def self.itemOrNull(uuid)
        entry = Index3::entryOrNull(uuid)
        return nil if entry.nil?
        entry["item"]
    end

    # Index3::commitItem(item)
    def self.commitItem(item)
        filepath = Index3::getDatabaseFilepath()
        Index3::insertUpdateItemAtFile(filepath, item)
    end

    # Items::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        item = Index3::itemOrNull(item)
        return if item.nil?
        item[attrname] = attrvalue
        Index3::commitItem(item)
    end

    # Index3::mikuTypes()
    def self.mikuTypes()
        mikuTypes = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select distinct(mikuType) as mikuType from index3", []) do |row|
            mikuTypes << row["mikuType"]
        end
        db.close
        mikuTypes
    end

    # Index3::mikyType(mikuType) -> Array[Item]
    def self.mikyType(mikuType)
        items = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index3 where mikuType=?", [mikuType]) do |row|
            items << JSON.parse(row["item"])
        end
        db.close
        items
    end

    # Index3::deleteItem(uuid)
    def self.deleteItem(uuid)
        Index3::deleteEntry(uuid)
    end
end
