
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

    # NxTimeCapsules::liveValue(capsule)
    def self.liveValue(capsule)
        capsule["value"] + Bank1::getValue(capsule["uuid"])
    end

    # NxTimeCapsules::maintenance()
    def self.maintenance()
        targetuuids = Items::mikuType("NxTimeCapsule").map{|item| item["targetuuid"] }.compact.uniq
        targetuuids.each{|targetuuid|
            puts "targetuuid: #{targetuuid}"
            capsules = Items::mikuType("NxTimeCapsule")
                        .select{|item| item["targetuuid"] == targetuuid }
                        .sort_by{|item| item["flight-data-27"]["calculated-start"] }
            firstPositive = capsules.select{|item| NxTimeCapsules::liveValue(item) >= 0 }.first
            firstNegative = capsules.select{|item| NxTimeCapsules::liveValue(item) < 0 }.first
            next if firstPositive.nil?
            next if firstNegative.nil?
            next if NxBalls::itemIsActive(firstPositive)
            next if NxBalls::itemIsActive(firstNegative)
            Items::setAttribute(firstNegative["uuid"], "value", firstNegative["value"] + NxTimeCapsules::liveValue(firstPositive))
            Items::destroy(firstPositive["uuid"])
        }
    end
end
