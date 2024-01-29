
class NxMissions

    # NxMissions::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes2::itemInit(uuid, "NxMission")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
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

    # NxMissions::recoveryTimeControl()
    def self.recoveryTimeControl()
        0.75
    end

    # NxMissions::muiItems()
    def self.muiItems()

        return [] if Bank2::recoveredAverageHoursPerDay("missions-control-4160-84b0-09a726873619") > NxMissions::recoveryTimeControl()

        Cubes2::mikuType("NxMission")
            .sort_by{|item| item["lastDoneUnixtime"] }
            .take(1)
    end
end
