# encoding: UTF-8

class Synthetic

    # Synthetic::register(datetime, id, timespan)
    def self.register(datetime, id, timespan)
        entry = "#{datetime}|#{id}|#{timespan}"
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/Synthetic.log", "a"){|f| f.puts(entry) }
    end

    # Synthetic::getRecordsInTimeOrder()
    def self.getRecordsInTimeOrder()
        IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/Synthetic.log")
            .lines
            .map{|line| line.strip }
            .select{|line| line.size > 0 }
            .map{|line|
                elements = line.split('|')
                {
                    "unixtime" => DateTime.parse(elements[0]).to_time.to_i,
                    "id"       => elements[1],
                    "timespan" => elements[2].to_f
                }
            }
    end

    # Synthetic::getSyntheticRecordsInTimeOrder()
    def self.getSyntheticRecordsInTimeOrder()
        Synthetic::getRecordsInTimeOrder()
            .reduce({}){|str, record|
                if str[record["id"]] then
                    str[record["id"]] << record
                else
                    str[record["id"]] = [ record ]
                end
                str
            }
            .to_a
            .select{|pair| pair[1].size == 1 }
            .map{|pair| pair[1] }
            .flatten
    end

    # Synthetic::getRecoveryTimeInHoursAfterHorizon(horizon)
    def self.getRecoveryTimeInHoursAfterHorizon(horizon)
        records = Synthetic::getSyntheticRecordsInTimeOrder()
        records = records.select{|record| record["unixtime"] >= horizon}
        return 0 if records.empty?
        unixtime1 = records[0]["unixtime"]
        unixtime2 = Time.new.to_f
        ratio = records.map{|record| record["timespan"] }.inject(0, :+).to_f/(unixtime2-unixtime1)
        ratio*24
    end

    # Synthetic::getRecoveryTimeInHours()
    def self.getRecoveryTimeInHours()
        rts = (1..7)
                .map{|i| Time.new.to_f - 86400*i }
                .map{|horizon| Synthetic::getRecoveryTimeInHoursAfterHorizon(horizon)}
        return 0 if rts.empty?
        rts.max
    end
end


