# encoding: UTF-8

class Bank1

    # ----------------------------------
    # Interface

    # Bank1::instanceFilepath()
    def self.instanceFilepath()
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

    # Bank1::record_filepaths()
    def self.record_filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/Bank")
            .select{|location| location[-7, 7] == ".record" }
            .map{|filepath|
                record = JSON.parse(IO.read(filepath))
                if record["date"] < CommonUtils::nDaysInTheFuture(-60) then
                    FileUtils.rm(filepath)
                    nil
                else
                    filepath
                end
            }.compact
    end

    # Bank1::getValueAtDate(uuid, date)
    def self.getValueAtDate(uuid, date)
        # not implemented
    end

    # Bank1::getValue(uuid)
    def self.getValue(uuid)
        # not implemented
    end

    # Bank1::put(uuid, date, value)
    def self.put(uuid, date, value)
        record = {
            "id"    => uuid,
            "date"  => date,
            "value" => value
        }
        filename = "#{CommonUtils::timeStringL22()}.record"
        filepath = "#{Config::pathToCatalystDataRepository()}/Bank/#{filename}"
        File.open(filepath, "w"){|f| f.puts(JSON.generate(record)) }
    end

    # ----------------------------------

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
        (0..6).map{|n| Bank1::averageHoursPerDayOverThePastNDays(uuid, n) }.max
    end
end
