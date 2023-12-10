
class NxStickies

    # NxStickies::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        DataCenter::itemInit(uuid, "NxSticky")
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "field11", coredataReference)
        DataCenter::itemOrNull(uuid)
    end

    # NxStickies::interactivelyIssueNew2(uuid, description)
    def self.interactivelyIssueNew2(uuid, description)
        DataCenter::itemInit(uuid, "NxSticky")
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxStickies::toString(item)
    def self.toString(item)
        "☀️  #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item).red}"
    end

    # NxStickies::listingItems()
    def self.listingItems()
        DataCenter::mikuType("NxSticky")
    end
end
