class TxEngines

    # -----------------------------------------------
    # Build

    # TxEngines::interactivelyMakeNewOrNull(ec = nil)
    def self.interactivelyMakeNewOrNull(ec = nil)
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
        return core["hours"].to_f/7
    end

    # TxEngines::weeklyDone(core)
    def self.weeklyDone(core)
        CommonUtils::datesSinceLastSaturday().reduce(0){|time, date| time + Bank2::getValueAtDate(core["uuid"], date) }.to_f/3600
    end

    # TxEngines::dayCompletionRatio(core)
    def self.dayCompletionRatio(core)
        x1 = TxEngines::todayDone(core).to_f/TxEngines::todayIdeal(core)
        x2 = Bank2::recoveredAverageHoursPerDay(core["uuid"]).to_f/TxEngines::todayIdeal(core)
        [0.9*x1 + 0.1*x2, x1].max
    end

    # TxEngines::weeklyCompletionRatioOrNull(core)
    def self.weeklyCompletionRatioOrNull(core)
        TxEngines::weeklyDone(core).to_f/core["hours"]
    end

    # TxEngines::listingCompletionRatio(core)
    def self.listingCompletionRatio(core)
        if TxEngines::weeklyCompletionRatioOrNull(core) >= 1 then
            return TxEngines::weeklyCompletionRatioOrNull(core)
        end
        TxEngines::dayCompletionRatio(core)
    end

    # TxEngines::suffix1(core)
    def self.suffix1(core)
        " (#{"%6.2f" % (100*TxEngines::dayCompletionRatio(core))} %, #{"%6.2f" % (100*TxEngines::weeklyCompletionRatioOrNull(core))} % of #{"%5.2f" % core["hours"]} hs)".green
    end

    # TxEngines::suffix2(item)
    def self.suffix2(item)
        return "" if item["engine-0020"].nil?
        TxEngines::suffix1(item["engine-0020"])
    end
end
