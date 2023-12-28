# encoding: UTF-8

class Bank

    # ----------------------------------
    # Interface

    # Bank::instanceFilepath()
    def self.instanceFilepath()
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Bank/Bank-#{Config::thisInstanceId()}.sqlite3"
        if !File.exist?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("create table Bank (_recorduuid_ string primary key, _id_ string, _date_ string, _value_ float)")
            db.close
        end
        filepath
    end

    # Bank::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Bank")
            .select{|location| location[-8, 8] == ".sqlite3" }
    end

    # Bank::getValueAtDate(uuid, date)
    def self.getValueAtDate(uuid, date)

        return $DATA_CENTER_DATA["bank"]
                    .select{|record| record["id"] == uuid }
                    .select{|record| record["date"] == date }
                    .map{|record| record["value"] }
                    .inject(0, :+)

        Bank::filepaths()
            .map{|filepath|
                value = 0
                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select * from Bank where _id_=? and _date_=?", [uuid, date]) do |row|
                    value = value + row["_value_"]
                end
                db.close
                value
            }
            .inject(0, :+)
    end

    # Bank::getValue(uuid)
    def self.getValue(uuid)

        return $DATA_CENTER_DATA["bank"]
                    .select{|record| record["id"] == uuid }
                    .map{|record| record["value"] }
                    .inject(0, :+)

        Bank::filepaths()
            .map{|filepath|
                value = 0
                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select * from Bank where _id_=?", [uuid]) do |row|
                    value = value + row["_value_"]
                end
                db.close
                value
            }
            .inject(0, :+)
    end

    # Bank::put(uuid, value)
    def self.put(uuid, value)
        $DATA_CENTER_DATA["bank"] << {
            "id"    => uuid,
            "date"  => CommonUtils::today(),
            "value" => value
        }
        $DATA_CENTER_UPDATE_QUEUE << {
            "type"  => "bank-record",
            "id"    => uuid,
            "date"  => CommonUtils::today(),
            "value" => value
        }

        return

        filepath = Bank::instanceFilepath()
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into Bank (_recorduuid_, _id_, _date_, _value_) values (?, ?, ?, ?)", [SecureRandom.uuid, uuid, CommonUtils::today(), value]
        db.close
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
