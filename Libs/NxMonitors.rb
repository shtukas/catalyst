
class NxMonitors

    # NxMonitors::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes::itemInit(uuid, "NxMonitor")
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        Cubes::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute(uuid, "description", description)
        Cubes::setAttribute(uuid, "field11", coredataref)
        Cubes::itemOrNull(uuid)
    end

    # NxMonitors::issueNew(uuid, description)
    def self.issueNew(uuid, description)
        Cubes::itemInit(uuid, "NxMonitor")
        Cubes::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute(uuid, "description", description)
        Cubes::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxMonitors::toString(item)
    def self.toString(item)
        "☀️  #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item).red}"
    end

    # NxMonitors::listingItems()
    def self.listingItems()
        Cubes::mikuType("NxMonitor")
    end
end
