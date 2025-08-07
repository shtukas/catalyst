
=begin
create table index4 (
    recorduuid text non null primary key,
    id text non null,
    unixtime integer non null,
    date text non null,
    value real non null
);
=end

class BankVault

    # ------------------------------------------------------
    # Basic IO management

    # BankVault::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/databases/index4-banking"
    end

    # BankVault::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(BankVault::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
    end

    # BankVault::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{BankVault::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # BankVault::initiateDatabaseFile() -> filepath
    def self.initiateDatabaseFile()
        filename = "#{SecureRandom.hex}.sqlite3"
        filepath = "#{BankVault::directory()}/#{filename}"
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
        BankVault::ensureContentAddressing(filepath)
    end

    # BankVault::extractEntryOrNullFromFilepath(filepath, recorduuid)
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

    # BankVault::insertUpdateEntryAtFilepath(filepath, recorduuid, id, unixtime, date, value)
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

    # BankVault::extractEntriesFromFile(filepath)
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

    # BankVault::mergeTwoDatabaseFiles(filepath1, filepath2) # -> filepath of the 
    def self.mergeTwoDatabaseFiles(filepath1, filepath2)
        # The logic here is to read the items from filepath2 and 
        # possibly add them to filepath1, if either:
        #   - there was no equivalent in filepath1
        #   - it's a newer record than the one in filepath1
        BankVault::extractEntriesFromFile(filepath2).each{|entry2|
            shouldInject = false
            entry1 = BankVault::extractEntryOrNullFromFilepath(filepath1, entry2["recorduuid"])
            if entry1.nil? then
                # filepath1 doesn't have that record from filepath2
                BankVault::insertUpdateEntryAtFilepath(filepath1, entry2["recorduuid"], entry2["id"], entry2["unixtime"], entry2["date"], entry2["value"])
            end
        }
        # Then when we are done, we delete filepath2
        FileUtils::rm(filepath2)
        BankVault::ensureContentAddressing(filepath1)
    end

    # BankVault::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = BankVault::filepaths()

        # This case should not really happen (anymore), so if the condition 
        # is true, let's error noisily.
        if filepaths.size == 0 then
            # return BankVault::initiateDatabaseFile()
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
            filepath1 = ListingDatabase::mergeTwoDatabaseFiles(filepath1, filepath)
        }
        filepath1
    end

    # BankVault::insertUpdateEntry(recorduuid, id, unixtime, date, value)
    def self.insertUpdateEntry(recorduuid, id, unixtime, date, value)
        puts "BankVault::insertUpdateEntry: #{[id, unixtime, date, value].join(', ')}".yellow
        filepath = BankVault::getDatabaseFilepath()
        BankVault::insertUpdateEntryAtFilepath(filepath, recorduuid, id, unixtime, date, value)
    end

    # ------------------------------------------------------
    # Interface

    # BankVault::getValue(id)
    def self.getValue(id)
        value = 0
        db = SQLite3::Database.new(BankVault::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index4 where id=?", [id]) do |row|
            value = value + row["value"]
        end
        db.close
        value
    end

    # BankVault::getValueAtDate(id, date)
    def self.getValueAtDate(id, date)
        value = 0
        db = SQLite3::Database.new(BankVault::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from index4 where id=? and date=?", [id, date]) do |row|
            value = value + row["value"]
        end
        db.close
        value
    end

    # BankVault::insertValue(id, date, value)
    def self.insertValue(id, date, value)
        recorduuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        BankVault::insertUpdateEntry(recorduuid, id, unixtime, date, value)
        BankDataRTCache::decacheValue(id)
    end

    # BankVault::getRecordsAll()
    def self.getRecordsAll()
        BankVault::extractEntriesFromFile(BankVault::getDatabaseFilepath())
    end

    # BankVault::getRecords(uuid)
    def self.getRecords(uuid)
        BankVault::getRecordsAll().select{|record|
            record["id"] == uuid
        }
    end

    # BankVault::maintenance()
    def self.maintenance()
        horizon = Time.new.to_i - 86400*90
        filepath = BankVault::getDatabaseFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from index4 where unixtime<?", [horizon])
        db.execute("vacuum", [])
        db.close
        BankVault::ensureContentAddressing(filepath)
    end
end
