class TxCores

    # -----------------------------------------------
    # Build

    # TxCores::interactivelyMakeNewOrNull(ec = nil)
    def self.interactivelyMakeNewOrNull(ec = nil)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["daily-hours", "weekly-hours"])
        return nil if type.nil?
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
        if type == "one-sitting" then
            return {
                "uuid"          => SecureRandom.uuid,
                "mikuType"      => "TxCore",
                "type"          => "one-sitting",
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

    # TxCores::todayDone(core)
    def self.todayDone(core)
        Bank2::getValueAtDate(core["uuid"], CommonUtils::today()).to_f/3600
    end

    # TxCores::todayIdeal(core)
    def self.todayIdeal(core)
        if core["type"] == "daily-hours" then
            return core["hours"]
        end
        if core["type"] == "weekly-hours" then
            return core["hours"].to_f/7
        end
        if core["type"] == "one-sitting" then
            return 0
        end
        raise "(error: 6854718b-24f5-4690-b479-5c8178a966c7): core: #{core}"
    end

    # TxCores::weeklyDone(core)
    def self.weeklyDone(core)
        CommonUtils::datesSinceLastSaturday().reduce(0){|time, date| time + Bank2::getValueAtDate(core["uuid"], date) }.to_f/3600
    end

    # TxCores::numbers(core)
    def self.numbers(core)
        if core["type"] == "daily-hours" then
            return [
                TxCores::todayDone(core),
                core["hours"],
                TxCores::weeklyDone(core),
                core["hours"]*7
            ]
        end
        if core["type"] == "weekly-hours" then
            return [
                TxCores::todayDone(core),
                core["hours"].to_f/7,
                TxCores::weeklyDone(core),
                core["hours"]
            ]
        end
        if core["type"] == "one-sitting" then
            return [
                0,
                1,
                0,
                0
            ]
        end
        raise "(error: 6854718b-24f5-4690-b479-5c8178a966c7): core: #{core}"
    end

    # TxCores::dayCompletionRatio(core)
    def self.dayCompletionRatio(core)
        x1 = TxCores::todayDone(core).to_f/TxCores::todayIdeal(core)
        x2 = Bank2::recoveredAverageHoursPerDay(core["uuid"]).to_f/TxCores::todayIdeal(core)
        [0.9*x1 + 0.1*x2, x1].max
    end

    # TxCores::weeklyCompletionRatioOrNull(core)
    def self.weeklyCompletionRatioOrNull(core)
        if core["type"] == "daily-hours" then
            raise "(error: 0b0b4e04-e4a6-41e6-84bf-49687ee49b41): core: #{core}"
        end
        TxCores::weeklyDone(core).to_f/core["hours"]
    end

    # TxCores::listingCompletionRatio(core)
    def self.listingCompletionRatio(core)
        if core["type"] == "daily-hours" then
            return TxCores::dayCompletionRatio(core)
        end
        if core["type"] == "weekly-hours" then
            if TxCores::weeklyCompletionRatioOrNull(core) >= 1 then
                return TxCores::weeklyCompletionRatioOrNull(core)
            end
            return TxCores::dayCompletionRatio(core)
        end
        if core["type"] == "one-sitting" then
            return 0.5
        end
        raise "(error: 2ba8c6dc-48fd-4155-a4f3-1cf65892acc1): core: #{core}"
    end

    # TxCores::suffix1(core, context = nil)
    def self.suffix1(core, context = nil)
        if core.nil? then
            return "".yellow
        end
        if context == "listing" then
            return ""
        end
        if context == "ns:projects:active" then
            if core["type"] == "daily-hours" then
                return " (#{"%6.2f" % (100*TxCores::dayCompletionRatio(core))} %           of daily:  #{"%5.2f" % core["hours"]} hs)".green
            end
            if core["type"] == "weekly-hours" then
                return " (#{"%6.2f" % (100*TxCores::dayCompletionRatio(core))} %, #{"%6.2f" % (100*TxCores::weeklyCompletionRatioOrNull(core))} % of weekly: #{"%5.2f" % core["hours"]} hs)".green
            end
        end
        ""
    end

    # TxCores::suffix2(item, context = nil)
    def self.suffix2(item, context = nil)
        return "" if item["engine-0020"].nil?
        TxCores::suffix1(item["engine-0020"], context)
    end
end
