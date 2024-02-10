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

    # TxEngines::weeklyHours(core)
    def self.weeklyHours(core)
        core["hours"]
    end

    # TxEngines::timeDoneSinceLastSaturdayExcludingTodayInHours(core)
    def self.timeDoneSinceLastSaturdayExcludingTodayInHours(core)
        dates = CommonUtils::datesSinceLastSaturday() - [CommonUtils::today()]
        dates.map{|date| Bank2::getValueAtDate(core["uuid"], date) }.inject(0, :+).to_f/3600
    end

    # TxEngines::remainingTimeForOngoingWeekInHours(core)
    def self.remainingTimeForOngoingWeekInHours(core)
        [TxEngines::weeklyHours(core) - TxEngines::timeDoneSinceLastSaturdayExcludingTodayInHours(core), 0].max
    end

    # TxEngines::remainingDaysInOngoingWeek()
    def self.remainingDaysInOngoingWeek()
        7 - CommonUtils::datesSinceLastSaturday().size
    end

    # TxEngines::todayIdealInHours(core)
    def self.todayIdealInHours(core)
        [ core["hours"].to_f/7 , TxEngines::remainingTimeForOngoingWeekInHours(core).to_f/TxEngines::remainingDaysInOngoingWeek() ].min
    end

    # TxEngines::dayCompletionRatioAgainstComputedtodayIdealInHours(core)
    def self.dayCompletionRatioAgainstComputedtodayIdealInHours(core)
        ti = TxEngines::todayIdealInHours(core)
        return 1 if ti == 0

        ratio1 = Bank2::getValueAtDate(core["uuid"], CommonUtils::today()).to_f/(3600*ti)
        ratio2 = Bank2::recoveredAverageHoursPerDay(core["uuid"]).to_f/ti

        0.8*ratio1 + 0.2*ratio2
    end

    # TxEngines::listingCompletionRatio(core)
    def self.listingCompletionRatio(core)
        TxEngines::dayCompletionRatioAgainstComputedtodayIdealInHours(core)
    end

    # TxEngines::toString(core)
    def self.toString(core)
        "(today: #{"%6.2f" % (100*TxEngines::dayCompletionRatioAgainstComputedtodayIdealInHours(core))} %, done: #{"%5.2f" % TxEngines::timeDoneSinceLastSaturdayExcludingTodayInHours(core)} of weekly: #{"%5.2f" % core["hours"]})".green
    end
end
