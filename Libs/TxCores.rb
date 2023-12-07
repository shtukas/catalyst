
class TxCores

    # -----------------------------------------------
    # Build

    # TxCores::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["daily-hours", "weekly-hours"])
        return nil if type.nil?
        if type == "daily-hours" then
            hours = LucilleCore::askQuestionAnswerAsString("daily hours (empty for abort): ")
            return nil if hours == ""
            hours = hours.to_f
            return nil if hours == 0
            return {
                "uuid"          => SecureRandom.uuid,
                "mikuType"      => "TxCore",
                "type"          => "daily-hours",
                "hours"         => hours,
            }
        end
        if type == "weekly-hours" then
            hours = LucilleCore::askQuestionAnswerAsString("weekly hours (empty for abort): ")
            return nil if hours == ""
            hours = hours.to_f
            return nil if hours == 0
            return {
                "uuid"          => SecureRandom.uuid,
                "mikuType"      => "TxCore",
                "type"          => "weekly-hours",
                "hours"         => hours
            }
        end
        raise "(error: 9ece0a71-f6bc-4b2d-ae27-3d4b5a0fac17)"
    end

    # TxCores::interactivelyMakeNew()
    def self.interactivelyMakeNew()
        core = TxCores::interactivelyMakeNewOrNull()
        return core if core
        TxCores::interactivelyMakeNew()
    end

    # -----------------------------------------------
    # Data

    # TxCores::coreDayHours(core)
    def self.coreDayHours(core)
        if core["type"] == "weekly-hours" then
            return core["hours"].to_f/7
        end
        if core["type"] == "daily-hours" then
            return core["hours"]
        end
        raise "(error: 1cd26e69-4d2b-4cf7-9497-9bc715ea8f44): core: #{core}"
    end

    # TxCores::coreDayCompletionRatio(core)
    def self.coreDayCompletionRatio(core)
        if core["type"] == "weekly-hours" then
            doneSinceLastSaturdayInSeconds = CommonUtils::datesSinceLastSaturday().reduce(0){|time, date| time + Bank::getValueAtDate(core["uuid"], date) }
            doneSinceLastSaturdayInHours = doneSinceLastSaturdayInSeconds.to_f/3600
            return doneSinceLastSaturdayInHours.to_f/core["hours"] if doneSinceLastSaturdayInHours >= core["hours"]
            dailyHours = core["hours"].to_f/7
            return Bank::recoveredAverageHoursPerDay(core["uuid"]).to_f/dailyHours
        end
        if core["type"] == "daily-hours" then
            dailyHours = core["hours"]
            todayhours = Bank::getValueAtDate(core["uuid"], CommonUtils::today()).to_f/3600
            return todayhours.to_f/dailyHours
        end
        raise "(error: 1cd26e69-4d2b-4cf7-9497-9bc715ea8f44): core: #{core}"
    end

    # TxCores::string1(core)
    def self.string1(core)
        "(#{"%6.2f" % (100*TxCores::coreDayCompletionRatio(core))} % of #{"%4.2f" % TxCores::coreDayHours(core)} hours)".green
    end

    # TxCores::string2(core)
    def self.string2(core)
        "(#{core["type"]}: #{core["hours"]})"
    end

    # TxCores::requiredTimeInSeconds(core)
    def self.requiredTimeInSeconds(core)
        TxCores::coreDayHours(core)*3600 - Bank::getValueAtDate(core["uuid"], CommonUtils::today())
    end
end
