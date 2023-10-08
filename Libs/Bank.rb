# encoding: UTF-8

class Bank

    # ----------------------------------
    # Interface

    # Bank::getValueAtDate(uuid, date)
    def self.getValueAtDate(uuid, date)

        return $BankOperator.getValueAtDate(uuid, date)

        value = 0
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Bank.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Bank where _id_=? and _date_=?", [uuid, date]) do |row|
            value = value + row["_value_"]
        end
        db.close
        value
    end

    # Bank::getValue(uuid)
    def self.getValue(uuid)
        return $BankOperator.getValue(uuid)

        value = 0
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Bank.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Bank where _id_=?", [uuid]) do |row|
            value = value + row["_value_"]
        end
        db.close
        value
    end

    # Bank::put(uuid, value)
    def self.put(uuid, value)
        Broadcasts::publishBankDeposit(uuid, CommonUtils::today(), value)
    end

    # ----------------------------------

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
end
