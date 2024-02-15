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

    # TxEngines::dailyHours(core)
    def self.dailyHours(core)
        TxEngines::weeklyHours(core).to_f/7
    end

    # TxEngines::listingCompletionRatio(core)
    def self.listingCompletionRatio(core)
        Bank2::recoveredAverageHoursPerDay(core["uuid"]).to_f/TxEngines::dailyHours(core)
    end

    # TxEngines::toString(core)
    def self.toString(core)
        "(today: #{"%6.2f" % (100*TxEngines::listingCompletionRatio(core))} % of weekly: #{"%5.2f" % core["hours"]})".green
    end
end
