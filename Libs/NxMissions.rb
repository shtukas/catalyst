
class NxMissions

    # NxMissions::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes2::itemInit(uuid, "NxMission")
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "lastDoneUnixtime", Time.new.to_i)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxMissions::toString(item)
    def self.toString(item)
        "🚀 (mission: start, stop, done) #{item["description"]}"
    end
end
