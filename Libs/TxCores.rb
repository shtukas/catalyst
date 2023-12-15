class TxCores

    # -----------------------------------------------
    # Build

    # TxCores::interactivelyMakeNewOrNull(ec = nil)
    def self.interactivelyMakeNewOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["booster","daily-hours", "weekly-hours", "blocking-until-done", "monitor"])
        return nil if type.nil?
        if type == "booster" then
            hours = LucilleCore::askQuestionAnswerAsString("daily hours (empty for abort): ")
            return nil if hours == ""
            hours = hours.to_f
            return nil if hours == 0
            expiry = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
            return {
                "uuid"     => ec ? ec["uuid"] : SecureRandom.uuid,
                "mikuType" => "TxCore",
                "type"     => "booster",
                "hours"    => hours,
                "expiry"   => expiry
            }
        end
        if type == "daily-hours" then
            hours = LucilleCore::askQuestionAnswerAsString("daily hours (empty for abort): ")
            return nil if hours == ""
            hours = hours.to_f
            return nil if hours == 0
            return {
                "uuid"          => ec ? ec["uuid"] : SecureRandom.uuid,
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
                "uuid"          => ec ? ec["uuid"] : SecureRandom.uuid,
                "mikuType"      => "TxCore",
                "type"          => "weekly-hours",
                "hours"         => hours
            }
        end
        if type == "blocking-until-done" then
            return {
                "uuid"          => ec ? ec["uuid"] : SecureRandom.uuid,
                "mikuType"      => "TxCore",
                "type"          => "blocking-until-done"
            }
        end
        if type == "monitor" then
            return {
                "uuid"          => ec ? ec["uuid"] : SecureRandom.uuid,
                "mikuType"      => "TxCore",
                "type"          => "monitor"
            }
        end
        raise "(error: 9ece0a71-f6bc-4b2d-ae27-3d4b5a0fac17)"
    end

    # TxCores::interactivelyMakeBoosterOrNull()
    def self.interactivelyMakeBoosterOrNull()
        hours = LucilleCore::askQuestionAnswerAsString("daily hours (empty for abort): ")
        return nil if hours == ""
        hours = hours.to_f
        return nil if hours == 0
        expiry = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "TxCore",
            "type"     => "booster",
            "hours"    => hours,
            "expiry"   => expiry
        }
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
        if core["type"] == "booster" then
            return core["hours"]
        end
        if core["type"] == "blocking-until-done" then
            return 1
        end
        if core["type"] == "monitor" then
            return 1
        end
        raise "(error: 63cdeae4-d616-44d6-abbd-f53595dc7e73): core: #{core}"
    end

    # TxCores::coreDayCompletionRatio(core)
    def self.coreDayCompletionRatio(core)
        return 0 if core.nil?
        if core["type"] == "weekly-hours" then
            doneSinceLastSaturdayInSeconds = CommonUtils::datesSinceLastSaturday().reduce(0){|time, date| time + Bank::getValueAtDate(core["uuid"], date) }
            doneSinceLastSaturdayInHours = doneSinceLastSaturdayInSeconds.to_f/3600
            return doneSinceLastSaturdayInHours.to_f/core["hours"] if doneSinceLastSaturdayInHours >= core["hours"]
            dailyHours = core["hours"].to_f/7
            return Bank::recoveredAverageHoursPerDay(core["uuid"]).to_f/dailyHours
        end
        if core["type"] == "daily-hours" then
            dailyHours = core["hours"]
            hoursDoneToday = Bank::getValueAtDate(core["uuid"], CommonUtils::today()).to_f/3600
            x1 = hoursDoneToday.to_f/dailyHours
            x2 = Bank::recoveredAverageHoursPerDay(core["uuid"]).to_f/dailyHours
            return [0.8*x1 + 0.2*x2, x1].max
        end
        if core["type"] == "booster" then
            dailyHours = core["hours"]
            hoursDoneToday = Bank::getValueAtDate(core["uuid"], CommonUtils::today()).to_f/3600
            x1 = hoursDoneToday.to_f/dailyHours
            x2 = Bank::recoveredAverageHoursPerDay(core["uuid"]).to_f/dailyHours
            return [0.8*x1 + 0.2*x2, x1].max
        end
        if core["type"] == "blocking-until-done" then
            return 0
        end
        if core["type"] == "monitor" then
            return 0
        end
        raise "(error: 1cd26e69-4d2b-4cf7-9497-9bc715ea8f44): core: #{core}"
    end

    # TxCores::string2(core)
    def self.string2(core)
        return "(core not found)" if core.nil?
        "(#{core["type"]}: #{core["hours"]})"
    end

    # TxCores::suffix1(core, context = nil)
    def self.suffix1(core, context = nil)
        if context == "listing" then
            return ""
        end
        if core["type"] == "blocking-until-done" then
            return "⏱️  ( blcking til done           )".green
        end
        if core["type"] == "monitor" then
            return "⏱️  ( monitor                    )".green
        end
        if core["type"] == "weekly-hours" then
            return "⏱️  (#{"%6.2f" % (100*TxCores::coreDayCompletionRatio(core))} % of weekly: #{"%5.2f" % core["hours"]} hs)".green
        end
        if core["type"] == "daily-hours" then
            return "⏱️  (#{"%6.2f" % (100*TxCores::coreDayCompletionRatio(core))} % of daily:  #{"%5.2f" % core["hours"]} hs)".green
        end
        
    end

    # TxCores::suffix2(item)
    def self.suffix2(item)
        return "" if item["engine-0020"].nil?
        " #{TxCores::suffix1(item["engine-0020"])}"
    end
end
