
class TxDailyEngines

    # -----------------------------------------------
    # Build

    # TxDailyEngines::make(uuid, hours)
    def self.make(uuid, hours)
        {
            "uuid"     => uuid,
            "mikuType" => "TxDailyEngine",
            "hours"    => hours.to_f,
        }
    end

    # TxDailyEngines::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        hours = LucilleCore::askQuestionAnswerAsString("daily recovery time (empty for abort): ")
        return nil if hours == ""
        return nil if hours == "0"
        TxDailyEngines::make(SecureRandom.uuid, hours)
    end

    # TxDailyEngines::interactivelyMakeEngine()
    def self.interactivelyMakeEngine()
        engine = TxDailyEngines::interactivelyMakeOrNull()
        return engine if engine
        TxDailyEngines::interactivelyMakeEngine()
    end

    # -----------------------------------------------
    # Data

    # TxDailyEngines::completionRatio(engine)
    def self.completionRatio(engine)
        Bank::recoveredAverageHoursPerDay(engine["uuid"]).to_f/(engine["hours"]*3600)
    end

    # TxDailyEngines::toString(engine)
    def self.toString(engine)
        "(⏱️  daily engine: #{"#{"%6.2f" % (100*TxDailyEngines::completionRatio(engine))}%".green} of #{"%5.2f" % (engine["hours"])} hours)"
    end

    # TxDailyEngine::shouldShow(engine)
    def self.shouldShow(engine)
        TxDailyEngines::completionRatio(engine) < 1
    end

    # -----------------------------------------------
    # Ops

end
