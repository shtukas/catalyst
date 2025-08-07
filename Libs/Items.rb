
=begin
create table items (
    uuid text non null primary key,
    utime real non null,
    item text non null,
    mikuType text non null,
    description text non null
);
CREATE INDEX index1 ON items(uuid, mikuType);
=end

class Items

    # ------------------------------------------------------
    # Basic IO management

    # Items::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/databases/index3-items"
    end

    # Items::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Items::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
    end

    # Items::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{Items::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # Items::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{Items::directory()}/#{filename}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table items (
            uuid text non null primary key,
            utime real non null,
            item text non null,
            mikuType text non null,
            description text non null
        )", [])
        db.execute("CREATE INDEX items_index ON items(uuid, mikuType);", [])
        db.commit
        db.close
        Items::ensureContentAddressing(filepath)
    end

    # Items::insertUpdateItemAtFile(filepath, item)
    def self.insertUpdateItemAtFile(filepath, item)
        uuid = item["uuid"]
        utime = Time.new.to_f
        mikuType = item["mikuType"]
        description = decideDescription(item)

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from items where uuid=?", [uuid])
        db.execute("insert into items (uuid, utime, item, mikuType, description) values (?, ?, ?, ?, ?)", [uuid, utime, JSON.generate(item), mikuType, description])
        db.commit
        db.close
        Items::ensureContentAddressing(filepath)
    end

    # Items::extractEntryOrNullFromFilepath(filepath, uuid)
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

    # Items::insertUpdateEntryComponents2(filepath, utime, item, mikuType, description)
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

    # Items::mergeTwoDatabaseFiles(filepath1, filepath2) # -> filepath of the 
    def self.mergeTwoDatabaseFiles(filepath1, filepath2)
        # The logic here is to read the items from filepath2 and 
        # possibly add them to filepath1, if either:
        #   - there was no equivalent in filepath1
        #   - it's a newer record than the one in filepath1
        Items::extractEntriesFromFile(filepath2).each{|entry2|
            shouldInject = false
            entry1 = Items::extractEntryOrNullFromFilepath(filepath1, entry2["item"]["uuid"])
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
                Items::insertUpdateEntryComponents2(filepath1, entry2["utime"], entry2["item"], entry2["mikuType"], entry2["description"])
            end
        }
        # Then when we are done, we delete filepath2
        FileUtils::rm(filepath2)
        Items::ensureContentAddressing(filepath1)
    end

    # Items::extractEntriesFromFile(filepath)
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

    # Items::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = Items::filepaths()

        # This case should not really happen (anymore), so if the condition 
        # is true, let's error noisily.
        if filepaths.size == 0 then
            # return Items::initiateDatabaseFile()
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
            filepath1 = Items::mergeTwoDatabaseFiles(filepath1, filepath)
        }

        filepath1
    end

    # Items::entryOrNull(uuid)
    def self.entryOrNull(uuid)
        Items::filepaths().each{|filepath|
            entry = Items::extractEntryOrNullFromFilepath(filepath, uuid)
            return entry if entry
        }
        nil
    end

    # Items::deleteEntry(uuid)
    def self.deleteEntry(uuid)
        
        # Version 1
        # We are not doign version 1 anymore, because 
        # A deletion in the local file at the same time as 
        # any change in another instance, would create two seperate file
        # that when merged brings back the deleted item (the merger sees an item 
        # in one file and not the other and thinks that it's a new item).

        #filepath = Items::getDatabaseFilepath()
        #db = SQLite3::Database.new(filepath)
        #db.busy_timeout = 117
        #db.busy_handler { |count| true }
        #db.results_as_hash = true
        #db.execute("delete from items where uuid=?", [uuid])
        #db.execute("vacuum", [])
        #db.close
        #Items::ensureContentAddressing(filepath)

        # Version 2
        Items::setAttribute(uuid, "mikuType", "NxDeleted")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
    end

    # ------------------------------------------------------
    # Support

    # Items::decideDescription(item)
    def self.decideDescription(item)
        return item["description"] if item["description"]
        raise "(error: d9a4a31c) I do not know how to determine the description for item: #{item}"
    end

    # ------------------------------------------------------
    # Interface

    # Items::init(uuid)
    def self.init(uuid)
        if Items::itemOrNull(uuid) then
            raise "(error: 0e16c053) this uuid is already in use, you cannot init it"
        end
        item = {
          "uuid" => uuid,
          "mikuType" => "NxLine",
          "unixtime" => Time.new.to_i,
          "datetime" => Time.new.utc.iso8601,
          "description" => "Default description for initialised item. If you are reading this, something didn't happen"
        }
        Items::commitItem(item)
    end

    # Items::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        entry = Items::entryOrNull(uuid)
        if entry.nil? then
            HardProblem::item_could_not_be_found_on_disk(uuid)
            return nil
        end
        entry["item"]
    end

    # Items::commitItem(item)
    def self.commitItem(item)
        filepath = Items::getDatabaseFilepath()
        Items::insertUpdateItemAtFile(filepath, item)
    end

    # Items::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        item = Items::itemOrNull(uuid)
        return if item.nil?
        item[attrname] = attrvalue
        Items::commitItem(item)
        HardProblem::item_attribute_has_been_updated(uuid, attrname, attrvalue)
    end

    # Items::items()
    def self.items()
        items = []
        db = SQLite3::Database.new(Items::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from items", []) do |row|
            items << JSON.parse(row["item"])
        end
        db.close
        items
    end

    # Items::mikuTypes()
    def self.mikuTypes()
        mikuTypes = []
        db = SQLite3::Database.new(Items::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select distinct(mikuType) as mikuType from items", []) do |row|
            mikuTypes << row["mikuType"]
        end
        db.close
        mikuTypes
    end

    # Items::mikuType(mikuType) -> Array[Item]
    def self.mikuType(mikuType)
        items = []
        db = SQLite3::Database.new(Items::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from items where mikuType=?", [mikuType]) do |row|
            items << JSON.parse(row["item"])
        end
        db.close
        items
    end

    # Items::deleteItem(uuid)
    def self.deleteItem(uuid)
        item = Items::itemOrNull(uuid)
        if item then
            HardProblem::item_is_being_destroyed(item)
        end
        Items::deleteEntry(uuid)
        HardProblem::item_has_been_destroyed(uuid)
    end

    # ------------------------------------------------------
    # Interface

    # Items::maintenance()
    def self.maintenance()
        archive_filepath = "#{Items::directory()}/archives/#{CommonUtils::today()}.sqlite3"
        if !File.exist?(archive_filepath) then
            FileUtils.cp(Items::getDatabaseFilepath(), archive_filepath)
        end
    end
end
