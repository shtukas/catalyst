# encoding: UTF-8

$BankVault = {}

class Bank

    # ----------------------------------
    # Interface

    # Bank::getValueAtDate(uuid, date)
    def self.getValueAtDate(uuid, date)
        Bank::filepaths()
            .map{|filepath| Bank::getValueAtDateInFile(filepath, uuid, date) }
            .inject(0, :+)
    end

    # Bank::getValue(uuid)
    def self.getValue(uuid)
        Bank::filepaths()
            .map{|filepath| Bank::getValueInFile(filepath, uuid) }
            .inject(0, :+)
    end

    # Bank::put(uuid, value)
    def self.put(uuid, value)
        Bank::commit(uuid, Time.new.to_i, Time.new.to_s[0, 10], value)
    end

    # Bank::commit(uuid, unixtime, date, value)
    def self.commit(uuid, unixtime, date, value)
        puts "Bank::commit(#{uuid}, #{date}, #{value})"

        filepaths = Bank::filepaths()

        filepath0 = Bank::spawnNewDatabase()

        db = SQLite3::Database.new(filepath0)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into bank (recordId, uuid, unixtime, date, value) values (?, ?, ?, ?, ?)", [SecureRandom.hex, uuid, unixtime, date, value]
        db.close
    end

    # ----------------------------------
    # Private (0)

    # Bank::capacitybase()
    def self.capacitybase()
        50
    end

    # ----------------------------------
    # Private (1)

    # Bank::spawnNewDatabase()
    def self.spawnNewDatabase()
        filepath = "#{Config::pathToCatalystData()}/Bank/#{CommonUtils::timeStringL22()}@#{CommonUtils::timeStringL22()}.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table bank (recordId text primary key, uuid text, unixtime float, date text, value float)", [])
        db.close
        filepath
    end

    # Bank::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystData()}/Bank")
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
            .sort
    end

    # ----------------------------------
    # Private (2)

    # Bank::getValueAtDateInFile(filepath, uuid, date)
    def self.getValueAtDateInFile(filepath, uuid, date)
        # This function can be memoised because the database files are content addressed 🎉

        vaultkey = "#{filepath}:#{uuid}:#{date}"
        if $BankVault[vaultkey] then
            return $BankVault[vaultkey]
        end

        value = 0
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from bank where uuid=? and date=?", [uuid, date]) do |row|
            value = value + row["value"]
        end
        db.close

        $BankVault[vaultkey] = value

        value
    end

    # Bank::getValueInFile(filepath, uuid)
    def self.getValueInFile(filepath, uuid)
        value = 0
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from bank where uuid=?", [uuid]) do |row|
            value = value + row["value"]
        end
        db.close
        value
    end

    # Bank::getTwoSmallestFiles()
    def self.getTwoSmallestFiles()
        Bank::filepaths().sort_by{|filepath| File.size(filepath) }.take(2).sort
    end

    # Bank::fileManagement()
    def self.fileManagement()

        if Bank::filepaths().size > Bank::capacitybase()*2 then
            puts "BankCore file management".green
            while Bank::filepaths().size > Bank::capacitybase() do
                filepath1, filepath2 = Bank::getTwoSmallestFiles()

                puts "filepath1: #{filepath1}"
                puts "filepath2: #{filepath2}"

                db1 = SQLite3::Database.new(filepath1)
                db2 = SQLite3::Database.new(filepath2)

                # We move all the objects from db1 to db2

                db1.busy_timeout = 117
                db1.busy_handler { |count| true }
                db1.results_as_hash = true
                db1.execute("select * from bank", []) do |row|
                    db2.execute "delete from bank where recordId = ?", [row["recordId"]]
                    db2.execute "insert into bank (recordId, uuid, unixtime, date, value) values (?, ?, ?, ?, ?)", [row["recordId"], row["uuid"], row["unixtime"], row["date"], row["value"]]
                end

                db1.close
                db2.close

                # Let's now delete the first file 
                FileUtils.rm(filepath1)

                # And rename the second one
                filepath2v2 = "#{Config::pathToCatalystData()}/Bank/#{File.basename(filepath2)[0, 22]}@#{CommonUtils::timeStringL22()}.sqlite3"
                FileUtils.mv(filepath2, filepath2v2)
            end
        end
    end

    # Bank::averageHoursPerDayOverThePastNDays(uuid, n)
    # n = 0 corresponds to today
    def self.averageHoursPerDayOverThePastNDays(uuid, n)
        range = (0..n)
        totalInSeconds = range.map{|indx| Bank::getValueAtDate(uuid, CommonUtils::nDaysInTheFuture(-indx)) }.inject(0, :+)
        totalInHours = totalInSeconds.to_f/3600
        average = totalInHours.to_f/(n+1)
        average
    end

    # Bank::recoveredAverageHoursPerDay(uuid)
    def self.recoveredAverageHoursPerDay(uuid)
        (0..6).map{|n| Bank::averageHoursPerDayOverThePastNDays(uuid, n) }.max
    end

    # Bank::averageHoursPerDayOverThePastNDays2(uuids, n)
    # n = 0 corresponds to today
    def self.averageHoursPerDayOverThePastNDays2(uuids, n)
        range = (0..n)
        totalInSeconds = range.map{|indx| uuids.map{|uuid| Bank::getValueAtDate(uuid, CommonUtils::nDaysInTheFuture(-indx))}.inject(0, :+) }.inject(0, :+)
        totalInHours = totalInSeconds.to_f/3600
        average = totalInHours.to_f/(n+1)
        average
    end

    # Bank::recoveredAverageHoursPerDay2(items)
    def self.recoveredAverageHoursPerDay2(items)
        uuids = items.map{|item| item["uuid"] }
        (0..6).map{|n| Bank::averageHoursPerDayOverThePastNDays2(uuids, n) }.max
    end

end
