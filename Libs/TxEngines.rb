class TxEngines

    # -----------------------------------------------
    # Build

    # TxEngines::interactivelyMakeNewOrNull(ec = nil)
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
                "mikuType"      => "TxEngine",
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
                "mikuType"      => "TxEngine",
                "type"          => "weekly-hours",
                "hours"         => hours
            }
        end
        raise "(error: 9ece0a71-f6bc-4b2d-ae27-3d4b5a0fac17)"
    end

    # TxEngines::interactivelyMakeNew()
    def self.interactivelyMakeNew()
        core = TxEngines::interactivelyMakeNewOrNull()
        return core if core
        TxEngines::interactivelyMakeNew()
    end

    # -----------------------------------------------
    # Data

    # TxEngines::todayDone(core)
    def self.todayDone(core)
        Bank2::getValueAtDate(core["uuid"], CommonUtils::today()).to_f/3600
    end

    # TxEngines::todayIdeal(core)
    def self.todayIdeal(core)
        if core["type"] == "daily-hours" then
            return core["hours"]
        end
        if core["type"] == "weekly-hours" then
            return core["hours"].to_f/7
        end
        raise "(error: 6854718b-24f5-4690-b479-5c8178a966c7): core: #{core}"
    end

    # TxEngines::weeklyDone(core)
    def self.weeklyDone(core)
        CommonUtils::datesSinceLastSaturday().reduce(0){|time, date| time + Bank2::getValueAtDate(core["uuid"], date) }.to_f/3600
    end

    # TxEngines::numbers(core)
    def self.numbers(core)
        if core["type"] == "daily-hours" then
            return [
                TxEngines::todayDone(core),
                core["hours"],
                TxEngines::weeklyDone(core),
                core["hours"]*7
            ]
        end
        if core["type"] == "weekly-hours" then
            return [
                TxEngines::todayDone(core),
                core["hours"].to_f/7,
                TxEngines::weeklyDone(core),
                core["hours"]
            ]
        end
        raise "(error: 6854718b-24f5-4690-b479-5c8178a966c7): core: #{core}"
    end

    # TxEngines::dayCompletionRatio(core)
    def self.dayCompletionRatio(core)
        x1 = TxEngines::todayDone(core).to_f/TxEngines::todayIdeal(core)
        x2 = Bank2::recoveredAverageHoursPerDay(core["uuid"]).to_f/TxEngines::todayIdeal(core)
        [0.9*x1 + 0.1*x2, x1].max
    end

    # TxEngines::weeklyCompletionRatioOrNull(core)
    def self.weeklyCompletionRatioOrNull(core)
        if core["type"] == "daily-hours" then
            raise "(error: 0b0b4e04-e4a6-41e6-84bf-49687ee49b41): core: #{core}"
        end
        TxEngines::weeklyDone(core).to_f/core["hours"]
    end

    # TxEngines::listingCompletionRatio(core)
    def self.listingCompletionRatio(core)
        if core["type"] == "daily-hours" then
            return TxEngines::dayCompletionRatio(core)
        end
        if core["type"] == "weekly-hours" then
            if TxEngines::weeklyCompletionRatioOrNull(core) >= 1 then
                return TxEngines::weeklyCompletionRatioOrNull(core)
            end
            return TxEngines::dayCompletionRatio(core)
        end
        raise "(error: 2ba8c6dc-48fd-4155-a4f3-1cf65892acc1): core: #{core}"
    end

    # TxEngines::suffix1(core)
    def self.suffix1(core)
        if core.nil? then
            return "".yellow
        end
        if core["type"] == "daily-hours" then
            return " (#{"%6.2f" % (100*TxEngines::dayCompletionRatio(core))} % of daily:  #{core["hours"]} hs)".green
        end
        if core["type"] == "weekly-hours" then
            return " (#{"%6.2f" % (100*TxEngines::dayCompletionRatio(core))} %, #{"%6.2f" % (100*TxEngines::weeklyCompletionRatioOrNull(core))} % of weekly: #{"%5.2f" % core["hours"]} hs)".green
        end
    end

    # TxEngines::suffix2(item)
    def self.suffix2(item)
        return "" if item["engine-0020"].nil?
        TxEngines::suffix1(item["engine-0020"])
    end
end
