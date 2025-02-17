# encoding: UTF-8

=begin

journal item:
    {
      "uuid": "1f7aa2a2-61a0-43ad-9d18-ffc55a90b092",
      "date": "2024-06-07",
      "value": 360.0
    }

=end

$Nx2E076AFD = nil

Thread.new {
    sleep 1
    loop {
        $Nx2E076AFD = CommonUtils::locationTrace("#{Config::pathToCatalystDataRepository()}/Bank")
        sleep 120
    }
}

class Bank1

    # ----------------------------------
    # Core

    # Bank1::getInstanceFilepathMakeIfMissing()
    def self.getInstanceFilepathMakeIfMissing()
        filepath = "#{Config::pathToCatalystDataRepository()}/Bank/Bank-#{Config::thisInstanceId()}.sqlite3"
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

    # Bank1::putInDatabase(uuid, date, value)
    def self.putInDatabase(uuid, date, value)
        db = SQLite3::Database.new("#{Config::pathToCatalystDataRepository()}/Bank/20240607-175857-039036.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("insert into Bank (_recorduuid_, _id_, _date_, _value_) values (?, ?, ?, ?)", [SecureRandom.hex, uuid, date, value])
        db.close
    end

    # Bank1::journal()
    def self.journal()
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/Bank")
            .select{|location| location[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # Bank1::processJournal()
    def self.processJournal()
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/Bank")
            .select{|location| location[-5, 5] == ".json" }
            .map{|filepath| 
                record = JSON.parse(IO.read(filepath))
                Bank1::putInDatabase(record["uuid"], record["date"], record["value"])
                FileUtils.rm(filepath)
            }
    end

    # ----------------------------------
    # Interface

    # Bank1::getValueAtDate(uuid, date)
    def self.getValueAtDate(uuid, date)
        value = 0
        db = SQLite3::Database.new("#{Config::pathToCatalystDataRepository()}/Bank/20240607-175857-039036.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Bank where _id_=? and _date_=?", [uuid, date]) do |row|
            value = value + row["_value_"]
        end
        db.close
        Bank1::journal().each{|record|
            if record["uuid"] == uuid and record["date"] == date then
                value = value + record["value"]
            end
        }
        value
    end

    # Bank1::getValue(uuid)
    def self.getValue(uuid)
        value = 0
        db = SQLite3::Database.new("#{Config::pathToCatalystDataRepository()}/Bank/20240607-175857-039036.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Bank where _id_=?", [uuid]) do |row|
            value = value + row["_value_"]
        end
        db.close
        Bank1::journal().each{|record|
            if record["uuid"] == uuid then
                value = value + record["value"]
            end
        }
        value
    end

    # Bank1::put(uuid, date, value)
    def self.put(uuid, date, value)
        update = {
            "uuid"  => uuid,
            "date"  => date,
            "value" => value
        }
        filepath = "#{Config::pathToCatalystDataRepository()}/Bank/#{CommonUtils::timeStringL22()}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(update)) }
        $Nx2E076AFD = SecureRandom.hex
    end

    # Bank1::getRecords(uuid)
    def self.getRecords(uuid)
        records = []
        db = SQLite3::Database.new("#{Config::pathToCatalystDataRepository()}/Bank/20240607-175857-039036.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Bank where _id_=?", [uuid]) do |row|
            records << row
        end
        db.close
        Bank1::journal().each{|record|
            if record["uuid"] == uuid then
                records << record
            end
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
        key = "#{$Nx2E076AFD}:21a49255-d882-45a1-984c-8f32e5eccf77:#{uuid}"
        value = XCache::getOrNull(key)
        return value.to_f if value
        value = (0..6).map{|n| Bank1::averageHoursPerDayOverThePastNDays(uuid, n) }.max
        XCache::set(key, value)
        value
    end
end
