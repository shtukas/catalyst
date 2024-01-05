
class NxMonitors

    # NxMonitors::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes2::itemInit(uuid, "NxMonitor")
        payload = TxPayload::interactivelyMakeNewOr(uuid)
        payload.each{|k, v| Cubes2::setAttribute(uuid, k, v) }
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # NxMonitors::issueNew(uuid, description)
    def self.issueNew(uuid, description)
        Cubes2::itemInit(uuid, "NxMonitor")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxMonitors::toString(item)
    def self.toString(item)
        "☀️  #{item["description"]}"
    end

    # NxMonitors::listingItems()
    def self.listingItems()
        Cubes2::mikuType("NxMonitor")
    end
end
