# encoding: UTF-8

class Bank1

    # ----------------------------------
    # Core

    # Bank1::getValueAtDate(uuid, date)
    def self.getValueAtDate(uuid, date)
        value = 0
        Instances::instanceIds().each{|instanceId|
            db = SQLite3::Database.new("#{Config::pathToCatalystDataRepository()}/Bank/#{instanceId}.sqlite3")
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from Bank where _id_=? and _date_=?", [uuid, date]) do |row|
                value = value + row["_value_"]
            end
            db.close
        }
        value
    end

    # ----------------------------------
    # Interface

    # Bank1::getValue(uuid)
    def self.getValue(uuid)
        value = 0
        Instances::instanceIds().each{|instanceId|
            db = SQLite3::Database.new("#{Config::pathToCatalystDataRepository()}/Bank/#{instanceId}.sqlite3")
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from Bank where _id_=?", [uuid]) do |row|
                value = value + row["_value_"]
            end
            db.close
        }
        value
    end

    # Bank1::put(uuid, date, value)
    def self.put(uuid, date, value)
        db = SQLite3::Database.new("#{Config::pathToCatalystDataRepository()}/Bank/#{Instances::thisInstanceId()}.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("insert into Bank (_recorduuid_, _id_, _date_, _value_) values (?, ?, ?, ?)", [SecureRandom.hex, uuid, date, value])
        db.close
    end

    # Bank1::getRecords(uuid)
    def self.getRecords(uuid)
        records = []
        Instances::instanceIds().each{|instanceId|
            db = SQLite3::Database.new("#{Config::pathToCatalystDataRepository()}/Bank/#{instanceId}.sqlite3")
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from Bank where _id_=?", [uuid]) do |row|
                records << row
            end
            db.close
        }
        records
    end

    # Bank1::averageHoursPerDayOverThePastNDays(uuid, n)
    # n = 0 corresponds to today
    def self.averageHoursPerDayOverThePastNDays(uuid, n)
        range = (0..n)
        totalInSeconds = range.map{|indx| Bank1::getValueAtDate(uuid, CommonUtils::nDaysInTheFuture(-indx)) }.inject(0, :+)
        totalInHours = totalInSeconds.to_f/3600
        average = totalInHours.to_f/(n+1)
        average
    end

    # Bank1::recoveredAverageHoursPerDay(uuid)
    def self.recoveredAverageHoursPerDay(uuid)
        value = (0..6).map{|n| Bank1::averageHoursPerDayOverThePastNDays(uuid, n) }.max
        value
    end
end
