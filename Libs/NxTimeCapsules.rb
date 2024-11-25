
class NxTimeCapsules

    # NxTimeCapsules::issue(description, value, flightdata, targetuuid or null)
    def self.issue(description, value, flightdata, targetuuid)
        uuid = SecureRandom.uuid
        Items::itemInit(uuid, "NxTimeCapsule")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "value", value)
        Items::setAttribute(uuid, "flight-data-27", flightdata)
        Items::setAttribute(uuid, "targetuuid", targetuuid)
        Items::itemOrNull(uuid)
    end

    # NxTimeCapsules::toString(item)
    def self.toString(item)
        vx = item["value"] + Bank1::getValue(item["uuid"])
        "⏱️  (#{vx}) #{item["description"]}"
    end

    # NxTimeCapsules::listingItems()
    def self.listingItems()
        Items::mikuType("NxTimeCapsule")
            .select{|item| item["value"] + Bank1::getValue(item["uuid"]) < 0 }
    end
end
