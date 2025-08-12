# encoding: UTF-8

class BankDataRTCache

    # sqlite3 rt-cache.sqlite3
    # sqlite> CREATE TABLE rt (uuid text non null primary key, utime real, value real non null, valid_on text non null);

    # BankDataRTCache::directory()
    def self.directory()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/databases/index5-banking-rt-cache"
    end

    # BankDataRTCache::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder(BankDataRTCache::directory())
            .select{|filepath| File.basename(filepath)[-8, 8] == ".sqlite3" }
            .select{|filepath| !File.basename(filepath).include?("sync-conflict") }
    end

    # BankDataRTCache::ensureContentAddressing(filepath)
    def self.ensureContentAddressing(filepath)
        filename2 = "#{Digest::SHA1.file(filepath).hexdigest}.sqlite3"
        filepath2 = "#{BankDataRTCache::directory()}/#{filename2}"
        return filepath if filepath == filepath2
        FileUtils.mv(filepath, filepath2)
        filepath2
    end

    # BankDataRTCache::insertUpdateComponentsAtFile(filepath, uuid, utime, value, valid_on)
    def self.insertUpdateComponentsAtFile(filepath, uuid, utime, value, valid_on)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.transaction
        db.execute("delete from rt where uuid=?", [uuid])
        db.execute("insert into rt (uuid, utime, value, valid_on) values (?, ?, ?, ?)", [uuid, utime, value, valid_on])
        db.commit
        db.close
        BankDataRTCache::ensureContentAddressing(filepath)
    end

    # BankDataRTCache::extractEntryOrNullFromFilepath(filepath, uuid)
    def self.extractEntryOrNullFromFilepath(filepath, uuid)
        entry = nil
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from rt where uuid=?", [uuid]) do |row|
            entry = {
                "uuid"     => row["uuid"],
                "utime"    => row["utime"],
                "value"    => row["value"],
                "valid_on" => row["valid_on"]
            }
        end
        db.close
        entry
    end

    # BankDataRTCache::extractEntriesFromFile(filepath)
    def self.extractEntriesFromFile(filepath)
        entries = []
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from rt", []) do |row|
            entries << {
                "uuid"     => row["uuid"],
                "utime"    => row["utime"],
                "value"    => row["value"],
                "valid_on" => row["valid_on"]
            }
        end
        db.close
        entries
    end

    # BankDataRTCache::insertUpdateComponentsAtFile(filepath, uuid, utime, value, valid_on)

    # BankDataRTCache::mergeTwoDatabaseFiles(filepath1, filepath2) # -> filepath of the 
    def self.mergeTwoDatabaseFiles(filepath1, filepath2)
        # The logic here is to read the items from filepath2 and 
        # possibly add them to filepath1, if either:
        #   - there was no equivalent in filepath1
        #   - it's a newer record than the one in filepath1
        BankDataRTCache::extractEntriesFromFile(filepath2).each{|entry2|
            shouldInject = false
            entry1 = BankDataRTCache::extractEntryOrNullFromFilepath(filepath1, entry2["uuid"])
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
                BankDataRTCache::insertUpdateComponentsAtFile(filepath1, entry2["uuid"], entry2["utime"], entry2["value"], entry2["valid_on"])
            end
        }
        # Then when we are done, we delete filepath2
        FileUtils::rm(filepath2)
        BankDataRTCache::ensureContentAddressing(filepath1)
    end

    # BankDataRTCache::getDatabaseFilepath()
    def self.getDatabaseFilepath()
        filepaths = BankDataRTCache::filepaths()

        # This case should not really happen (anymore), so if the condition 
        # is true, let's error noisily.
        if filepaths.size == 0 then
            # return Items::initiateDatabaseFile()
            raise "(error: 73dd7dae)"
        end

        if filepaths.size == 1 then
            return filepaths[0]
        end

        filepath1 = filepaths.shift
        filepaths.each{|filepath|
            # The logic here is to read the items from filepath2 and 
            # possibly add them to filepath1.
            # We get an updated filepath1 because of content addressing.
            filepath1 = BankDataRTCache::mergeTwoDatabaseFiles(filepath1, filepath)
        }

        filepath1
    end

    # ----------------------------------------------------

    # BankDataRTCache::insertValueInCache(uuid, value)
    def self.insertValueInCache(uuid, value)
        db = SQLite3::Database.new(BankDataRTCache::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from rt where uuid=?", [uuid])
        db.execute("insert into rt (uuid, utime, value, valid_on) values (?, ?, ?, ?)", [uuid, Time.new.to_f, value, CommonUtils::today()])
        db.close
    end

    # BankDataRTCache::recoveredAverageHoursPerDayFromCacheOrNull(uuid)
    def self.recoveredAverageHoursPerDayFromCacheOrNull(uuid)
        value = nil
        db = SQLite3::Database.new(BankDataRTCache::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from rt where uuid=? and valid_on=?", [uuid, CommonUtils::today()]) do |row|
            value = row["value"]
        end
        db.close
        value
    end

    # BankDataRTCache::decacheValue(uuid)
    def self.decacheValue(uuid)
        db = SQLite3::Database.new(BankDataRTCache::getDatabaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from rt where uuid=?", [uuid])
        db.close
    end
end

class BankData

    # BankData::averageHoursPerDayOverThePastNDays(uuid, n)
    # n = 0 corresponds to today
    def self.averageHoursPerDayOverThePastNDays(uuid, n)
        range = (0..n)
        totalInSeconds = range.map{|indx| BankVault::getValueAtDate(uuid, CommonUtils::nDaysInTheFuture(-indx)) }.inject(0, :+)
        totalInHours = totalInSeconds.to_f/3600
        average = totalInHours.to_f/(n+1)
        average
    end

    # BankData::recoveredAverageHoursPerDay(uuid)
    def self.recoveredAverageHoursPerDay(uuid)
        value = BankDataRTCache::recoveredAverageHoursPerDayFromCacheOrNull(uuid)
        return value if value
        puts "BankData::recoveredAverageHoursPerDay: computing uuid #{uuid} from zero".yellow
        value = (0..6).map{|n| BankData::averageHoursPerDayOverThePastNDays(uuid, n) }.max
        BankDataRTCache::insertValueInCache(uuid, value)
        value
    end
end
