# encoding: UTF-8

class Bank2

    # Bank2::put(uuid, value)
    def self.put(uuid, value)
        $DATA_CENTER_DATA["bank"] << {
            "id"    => uuid,
            "date"  => CommonUtils::today(),
            "value" => value
        }
        $DATA_CENTER_UPDATE_QUEUE << {
            "type"  => "bank-put",
            "id"    => uuid,
            "date"  => CommonUtils::today(),
            "value" => value
        }
        DataProcessor::processQueue()
    end

    # Bank2::getRecords(uuid)
    def self.getRecords(uuid)
        $DATA_CENTER_DATA["bank"]
            .select{|record| record["id"] == uuid }
    end

    # Bank2::getValueAtDate(uuid, date)
    def self.getValueAtDate(uuid, date)
        Bank2::getRecords(uuid)
            .select{|record| record["date"] == date }
            .map{|record| record["value"] }
            .inject(0, :+)
    end

    # Bank2::getValue(uuid)
    def self.getValue(uuid)
        Bank2::getRecords(uuid)
            .map{|record| record["value"] }
            .inject(0, :+)
    end

    # Bank2::averageHoursPerDayOverThePastNDays(uuid, n)
    def self.averageHoursPerDayOverThePastNDays(uuid, n)
        range = (0..n)
        totalInSeconds = range.map{|indx| Bank2::getValueAtDate(uuid, CommonUtils::nDaysInTheFuture(-indx)) }.inject(0, :+)
        totalInHours = totalInSeconds.to_f/3600
        average = totalInHours.to_f/(n+1)
        average
    end

    # Bank2::recoveredAverageHoursPerDay(uuid)
    def self.recoveredAverageHoursPerDay(uuid)
        (0..6).map{|n| Bank2::averageHoursPerDayOverThePastNDays(uuid, n) }.max
    end
end
