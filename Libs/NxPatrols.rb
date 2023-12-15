
class NxPatrols

    # NxPatrols::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        DataCenter::itemInit(uuid, "NxPatrol")
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxPatrols::toString(item)
    def self.toString(item)
        "🚁 #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item).red}"
    end
end
