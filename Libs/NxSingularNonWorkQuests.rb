
class NxSingularNonWorkQuests

    # NxSingularNonWorkQuests::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes2::itemInit(uuid, "NxSingularNonWorkQuest")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxSingularNonWorkQuests::ratio()
    def self.ratio()
        Bank2::recoveredAverageHoursPerDay("043c1f2e-3baa-4313-af1c-22c4b6fcb33b").to_f/NxSingularNonWorkQuests::recoveryTimeControl()
    end

    # NxSingularNonWorkQuests::toString(item)
    def self.toString(item)
        ratiostr = "(#{(100 * NxSingularNonWorkQuests::ratio()).round(2)} % of #{NxSingularNonWorkQuests::recoveryTimeControl()} hs)".green
        "🚴‍♂️ (mission: start, stop, done) #{item["description"]} #{ratiostr}"
    end

    # NxSingularNonWorkQuests::recoveryTimeControl()
    def self.recoveryTimeControl()
        0.75
    end

    # NxSingularNonWorkQuests::itemsInOrder()
    def self.itemsInOrder()
        Cubes2::mikuType("NxSingularNonWorkQuest")
            .sort_by{|item| item["unixtime"] }
    end

    # NxSingularNonWorkQuests::muiItems()
    def self.muiItems()
        return [] if NxSingularNonWorkQuests::ratio() >= 1
        NxSingularNonWorkQuests::itemsInOrder().take(1)
    end
end
