
class NxPatrols

    # NxPatrols::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes::itemInit(uuid, "NxPatrol")
        Cubes::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute(uuid, "description", description)
        CacheWS::emit("mikutype-has-been-modified:NxPatrol")
        Cubes::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxPatrols::toString(item)
    def self.toString(item)
        "🚁 #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item).red}"
    end
end
