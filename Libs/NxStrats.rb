
class NxStrats

    # NxStrats::interactivelyIssueNewOrNull(description, bottomuuid)
    def self.interactivelyIssueNewOrNull(description, bottomuuid)
        uuid = SecureRandom.uuid
        Items::itemInit(uuid, "NxStrat")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "bottomuuid", bottomuuid)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxStrats::toString(item)
    def self.toString(item)
        "🪄 #{item["description"]}"
    end

    # NxStrats::topOrNull(bottomuuid)
    def self.topOrNull(bottomuuid)
        Items::mikuType("NxStrat")
            .select{|item| item["bottomuuid"] == bottomuuid }
            .first
    end

    # ------------------
    # Ops

    # NxStrats::garbageCollection()
    def self.garbageCollection()
        Items::mikuType("NxStrat").each{|item|
            if Items::itemOrNull(item["bottomuuid"]).nil? then
                Items::destroy(item["uuid"])
            end
        }
    end

end
