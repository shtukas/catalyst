
class NxRingworldMissions

    # NxRingworldMissions::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes2::itemInit(uuid, "NxRingworldMission")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "lastDoneUnixtime", Time.new.to_i)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxRingworldMissions::toString(item)
    def self.toString(item)
        ratiostring = "[#{"%6.2f" % NxRingworldMissions::ratio()}]".green
        "⭕️ #{ratiostring} (mission: start, stop, done) #{item["description"]}"
    end

    # NxRingworldMissions::recoveryTimeControl()
    def self.recoveryTimeControl()
        0.75
    end

    # NxRingworldMissions::itemsInOrder()
    def self.itemsInOrder()
        Cubes2::mikuType("NxRingworldMission")
            .sort_by{|item| item["lastDoneUnixtime"] }
    end

    # NxRingworldMissions::ratio()
    def self.ratio()
        [Bank2::recoveredAverageHoursPerDay("3413fd90-cfeb-4a66-af12-c1fc3eefa9ce"), 0].max.to_f/NxRingworldMissions::recoveryTimeControl()
    end

    # NxRingworldMissions::muiItems()
    def self.muiItems()
        return [] if NxRingworldMissions::ratio() >= 1
        NxRingworldMissions::itemsInOrder().take(1)
    end

    # NxRingworldMissions::metric(item)
    def self.metric(item)
        [0, NxRingworldMissions::recoveryTimeControl() - Bank2::recoveredAverageHoursPerDay("3413fd90-cfeb-4a66-af12-c1fc3eefa9ce")]
    end
end
