
class TxDeadline

    # -----------------------------------------------
    # Build

    # TxDeadline::make(uuid, unixtime)
    def self.make(uuid, unixtime)
        {
            "uuid"     => uuid,
            "mikuType" => "TxDeadline",
            "unixtime" => unixtime
        }
    end

    # TxDeadline::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        puts "making deadline:"
        unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
        return nil if unixtime.nil?
        TxDeadline::make(SecureRandom.hex, unixtime)
    end

    # TxDeadline::interactivelyMakeDeadline()
    def self.interactivelyMakeDeadline()
        deadline = TxDeadline::interactivelyMakeOrNull()
        return deadline if deadline
        TxDeadline::interactivelyMakeDeadline()
    end

    # -----------------------------------------------
    # Data

    # TxDeadline::toString(deadline)
    def self.toString(deadline)
        timespan = deadline["unixtime"] - Time.new.to_f
        "💣 deadline: #{Time.at(deadline["unixtime"]).to_s}, #{(timespan.to_f/86400).round(2)} days left"
    end

    # TxDeadline::deadlineSuffix(item)
    def self.deadlineSuffix(item)
        return "" if item["deadline"].nil?
        " (#{TxDeadline::toString(item["deadline"])})"
    end

    # TxDeadline::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxTask")
            .select{|item| item["deadline"] }
            .sort_by{|item| item["unixtime"] }
    end
end
