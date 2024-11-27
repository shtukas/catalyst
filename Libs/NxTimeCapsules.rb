
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
            capsules = Items::mikuType("NxTimeCapsule")
                        .select{|item| item["targetuuid"] == targetuuid }
                        .sort_by{|item| item["flight-data-27"]["calculated-start"] }
            firstPositive = capsules.select{|item| NxTimeCapsules::liveValue(item) >= 0 }.first
            firstNegative = capsules.select{|item| NxTimeCapsules::liveValue(item) < 0 }.first
            next if firstPositive.nil?
            next if firstNegative.nil?
            next if NxBalls::itemIsActive(firstPositive)
            next if NxBalls::itemIsActive(firstNegative)
            puts "capsule merging for targetuuid: #{targetuuid}"
            Items::setAttribute(firstNegative["uuid"], "value", firstNegative["value"] + NxTimeCapsules::liveValue(firstPositive))
            Items::destroy(firstPositive["uuid"])
        }
    end

    # NxTimeCapsules::getCapsulesForTarget(targetuuid)
    def self.getCapsulesForTarget(targetuuid)
        Items::mikuType("NxTimeCapsule")
            .select{|item| item["targetuuid"] == targetuuid }
    end

    # NxTimeCapsules::getFirstCapsuleForTargetOrNull(targetuuid)
    def self.getFirstCapsuleForTargetOrNull(targetuuid)
        NxTimeCapsules::getCapsulesForTarget(targetuuid)
            .sort_by{|item| item["flight-data-27"]["calculated-start"] }
            .first
    end

    # NxTimeCapsules::constellation(targetuuid, description, spreadTimeSpanInDays, totalCapsuleTimeInHours)
    def self.constellation(targetuuid, description, spreadTimeSpanInDays, totalCapsuleTimeInHours)
        singleCapsuleDurationInSeconds = (3600 * totalCapsuleTimeInHours).to_f/20
        startTimes = (1..20).map{|i| Time.new.to_i + 12*3600 + rand * 86400*spreadTimeSpanInDays }
        flights = startTimes.map{|start|
            {
                "version"            => NxFlightData::version(),
                "calculated-start"   => start,
                "estimated-duration" => singleCapsuleDurationInSeconds 
            }
        }
        flights
            .sort_by{|flightdata| flightdata["calculated-start"] }
            .each{|flightdata|
                puts "constellation: launching capsule for `#{description}`, duration: #{singleCapsuleDurationInSeconds}, at #{Time.at(flightdata["calculated-start"]).utc.iso8601}"
                NxTimeCapsules::issue("capsule for: #{description}", -singleCapsuleDurationInSeconds, flightdata, targetuuid)
            }
    end
end
