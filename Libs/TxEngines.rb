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
            "uuid"     => ec ? ec["uuid"] : SecureRandom.uuid,
            "mikuType" => "TxEngine",
            "hours"    => hours
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

    # TxEngines::todayIdeal(core)
    def self.todayIdeal(core)
        return core["hours"].to_f/7
    end

    # TxEngines::dayCompletionRatio(core)
    def self.dayCompletionRatio(core)
        Bank2::recoveredAverageHoursPerDay(core["uuid"]).to_f/TxEngines::todayIdeal(core)
    end

    # TxEngines::weeklyDone(core)
    def self.weeklyDone(core)
        CommonUtils::datesSinceLastSaturday().reduce(0){|time, date| time + Bank2::getValueAtDate(core["uuid"], date) }.to_f/3600
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

    # TxEngines::toString(core)
    def self.toString(core)
        "(#{"%6.2f" % (100*TxEngines::dayCompletionRatio(core))} %, #{"%6.2f" % (100*TxEngines::weeklyCompletionRatioOrNull(core))} % of #{"%5.2f" % core["hours"]} hs)".green
    end
end
