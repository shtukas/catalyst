
=begin
create table index4 (
    recorduuid text non null primary key,
    id text non null,
    unixtime integer non null,
    date text non null,
    value real non null
);
=end

class Index4

    # ------------------------------------------------------
    # Basic IO management

    # Index4::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/indices/index4-banking"
    end

    # Index4::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(Index4::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
    end

    # Index4::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{Index4::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # Index4::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{Index4::directory()}/#{filename}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("create table index4 (
            recorduuid text non null primary key,
            id text non null,
            unixtime integer non null,
            date text non null,
            value real non null
        )", [])
        db.commit
        db.close
        Index4::ensureContentAddressing(filepath)
    end

    # Index4::extractEntryOrNullFromFilepath(filepath, recorduuid)
    def self.extractEntryOrNullFromFilepath(filepath, recorduuid)
        entry = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index4 where recorduuid=?", [recorduuid]) do |row|
            entry = {
                "recorduuid" => row["recorduuid"],
                "id"         => row["id"],
                "unixtime"   => row["unixtime"],
                "date"       => row["date"],
                "value"      => row["value"]
            }
        end
        db.close
        entry
    end

    # Index4::insertUpdateEntryAtFilepath(filepath, recorduuid, id, unixtime, date, value)
    def self.insertUpdateEntryAtFilepath(filepath, recorduuid, id, unixtime, date, value)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from index4 where recorduuid=?", [recorduuid])
        db.execute("insert into index4 (recorduuid, id, unixtime, date, value) values (?, ?, ?, ?, ?)", [recorduuid, id, unixtime, date, value])
        db.commit
        db.close
    end

    # Index4::extractEntriesFromFile(filepath)
    def self.extractEntriesFromFile(filepath)
        entries = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index4", []) do |row|
            entries << {
                "recorduuid" => row["recorduuid"],
                "id"         => row["id"],
                "unixtime"   => row["unixtime"],
                "date"       => row["date"],
                "value"      => row["value"]
            }
        end
        db.close
        entries
    end

    # Index4::mergeTwoDatabaseFiles(filepath1, filepath2) # -> filepath of the 
    def self.mergeTwoDatabaseFiles(filepath1, filepath2)
        # The logic here is to read the items from filepath2 and 
        # possibly add them to filepath1, if either:
        #   - there was no equivalent in filepath1
        #   - it's a newer record than the one in filepath1
        Index4::extractEntriesFromFile(filepath2).each{|entry2|
            shouldInject = false
            entry1 = Index4::extractEntryOrNullFromFilepath(filepath1, entry2["recorduuid"])
            if entry1.nil? then
                # filepath1 doesn't have that record from filepath2
                Index4::insertUpdateEntryAtFilepath(filepath1, entry2["recorduuid"], entry2["id"], entry2["unixtime"], entry2["date"], entry2["value"])
            end
        }
        # Then when we are done, we delete filepath2
        FileUtils::rm(filepath2)
        Index4::ensureContentAddressing(filepath1)
    end

    # Index4::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = Index4::filepaths()

        # This case should not really happen (anymore), so if the condition 
        # is true, let's error noisily.
        if filepaths.size == 0 then
            # return Index4::initiateDatabaseFile()
            raise "(error: c83229f3)"
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

    # Index4::insertUpdateEntry(recorduuid, id, unixtime, date, value)
    def self.insertUpdateEntry(recorduuid, id, unixtime, date, value)
        filepath = Index4::getDatabaseFilepath()
        Index4::insertUpdateEntryAtFilepath(filepath, recorduuid, id, unixtime, date, value)
    end

    # ------------------------------------------------------
    # Interface

    # Index4::getValue(id)
    def self.getValue(id)
        value = 0
        db = SQLite3::Database.new(Index4::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index4 where id=?", [id]) do |row|
            value = value + row["value"]
        end
        db.close
        value
    end

    # Index4::getValueAtDate(id, date)
    def self.getValueAtDate(id, date)
        value = 0
        db = SQLite3::Database.new(Index4::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index4 where id=? and date=?", [id, date]) do |row|
            value = value + row["value"]
        end
        db.close
        value
    end

    # Index4::insertValue(id, date, value)
    def self.insertValue(id, date, value)
        recorduuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        Index4::insertUpdateEntry(recorduuid, id, unixtime, date, value)
    end

    # Index4::getRecords()
    def self.getRecords()
        Index4::extractEntriesFromFile(Index4::getDatabaseFilepath())
    end

    # Index4::maintenance()
    def self.maintenance()
        horizon = Time.new.to_i - 86400*90
        filepath = Index4::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from index4 where unixtime<?", [horizon])
        db.execute("vacuum", [])
        db.close
        Index4::ensureContentAddressing(filepath)
    end
end
