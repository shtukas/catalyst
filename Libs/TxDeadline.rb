
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
        "(💣 deadline: #{Time.at(deadline["unixtime"]).to_s}, #{(timespan.to_f/86400).round(2)} days left)"
    end

    # TxDeadline::listingItems()
    def self.listingItems()
        CatalystSharedCache::getOrDefaultValue("81154794-6d4f-43d5-9711-35e03a3146d1", [])
            .map{|uuid| DarkEnergy::itemOrNull(uuid) }
            .compact
            .sort_by{|item| item["drivers"].select{|driver| driver["mikuType"] == "TxDeadline" }.first["unixtime"] }
    end

    # -----------------------------------------------
    # Ops

    # TxDeadline::maintenance()
    def self.maintenance()
        uuids = DarkEnergy::all()
            .select{|item| item["drivers"] }
            .select{|item| item["drivers"].any?{|driver| driver["mikuType"] == "TxDeadline" } }
            .map{|item| item["uuid"] }
        CatalystSharedCache::set("81154794-6d4f-43d5-9711-35e03a3146d1", uuids)
    end

end
