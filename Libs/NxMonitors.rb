
class NxMonitors

    # NxMonitors::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        DataCenter::itemInit(uuid, "NxMonitor")
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "field11", coredataref)
        DataCenter::itemOrNull(uuid)
    end

    # NxMonitors::issueNew(uuid, description)
    def self.issueNew(uuid, description)
        DataCenter::itemInit(uuid, "NxMonitor")
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxMonitors::toString(item)
    def self.toString(item)
        "☀️  #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item).red}"
    end

    # NxMonitors::listingItems()
    def self.listingItems()
        DataCenter::mikuType("NxMonitor")
    end
end
