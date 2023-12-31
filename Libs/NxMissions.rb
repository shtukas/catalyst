
class NxMissions

    # NxMissions::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes::itemInit(uuid, "NxMission")
        Cubes::setAttribute(uuid, "description", description)
        Cubes::setAttribute(uuid, "lastDoneUnixtime", Time.new.to_i)
        Cubes::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxMissions::toString(item)
    def self.toString(item)
        "🚀 (mission: start, stop, done) #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item).red}"
    end
end
