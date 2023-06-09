
class NxTimes

    # NxTimes::issue(time, description)
    def self.issue(time, description)
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxTime", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "time", time)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxTimes::toString(item)
    def self.toString(item)
        "(time) [#{item["time"]}] #{item["description"]}"
    end

    # NxTimes::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxTime")
            .sort_by{|item| item["time"] }
    end
end