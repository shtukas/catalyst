
class NxTimes

    # NxTimes::issue(time, description)
    def self.issue(time, description)
        uuid = SecureRandom.uuid
        Solingen::init("NxTime", uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "time", time)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::getItemOrNull(uuid)
    end

    # NxTimes::toString(item)
    def self.toString(item)
        "(time) [#{item["time"]}] #{item["description"]}"
    end

    # NxTimes::listingItems()
    def self.listingItems()
        Solingen::mikuTypeItems("NxMonitorLongs")
            .sort_by{|item| item["time"] }
    end
end