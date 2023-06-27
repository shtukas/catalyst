
class TxEngines

    # TxEngines::interactivelyMakeEngineOrNull()
    def self.interactivelyMakeEngineOrNull()
        hours = LucilleCore::askQuestionAnswerAsString("engine hours (empty for abort): ")
        return nil if hours == ""
        return nil if hours == "0"
        {
            "uuid"          => SecureRandom.uuid,
            "hours"         => hours.to_f,
            "lastResetTime" => Time.new.to_f,
            "capsule"       => SecureRandom.hex
        }
    end

    # TxEngines::engine_maintenance(thread, engine)
    def self.engine_maintenance(thread, engine)
        return nil if Bank::getValue(engine["capsule"]).to_f/3600 < engine["hours"]
        return nil if (Time.new.to_i - engine["lastResetTime"]) < 86400*7
        puts "> I am about to reset engine of #{NxShips::toString(thread)}"
        LucilleCore::pressEnterToContinue()
        Bank::reset(engine["capsule"])
        if !LucilleCore::askQuestionAnswerAsBoolean("> continue with #{engine["hours"]} hours ? ") then
            hours = LucilleCore::askQuestionAnswerAsString("specify period load in hours (empty for the current value): ")
            if hours.size > 0 then
                engine["hours"] = hours.to_f
            end
        end
        engine["lastResetTime"] = Time.new.to_i
        engine
    end

    # TxEngines::dayCompletionRatio(engine)
    def self.dayCompletionRatio(engine)
        Bank::getValueAtDate(engine["uuid"], CommonUtils::today()).to_f/((engine["hours"]*3600).to_f/5)
    end

    # TxEngines::periodCompletionRatio(engine)
    def self.periodCompletionRatio(engine)
        Bank::getValue(engine["capsule"]).to_f/(engine["hours"]*3600)
    end

    # TxEngines::engineCompletionRatio(engine)
    def self.engineCompletionRatio(engine)
        period = TxEngines::periodCompletionRatio(engine)
        return period if period >= 1
        day = TxEngines::dayCompletionRatio(engine)
        return day if day >= 1
        0.9*day + 0.1*period
    end

    # TxEngines::toString(engine)
    def self.toString(engine)
        strings = []

        strings << "⏱️  (engine: today: #{"#{"%6.2f" % (100*TxEngines::dayCompletionRatio(engine))}%".green} of #{"%5.2f" % (engine["hours"].to_f/5)} hours"
        strings << ", period: #{"#{"%6.2f" % (100*TxEngines::periodCompletionRatio(engine))}%".green} of #{"%5.2f" % engine["hours"]} hours"

        hasReachedObjective = Bank::getValue(engine["capsule"]) >= engine["hours"]*3600
        timeSinceResetInDays = (Time.new.to_i - engine["lastResetTime"]).to_f/86400
        itHassBeenAWeek = timeSinceResetInDays >= 7

        if hasReachedObjective and itHassBeenAWeek then
            strings << ", awaiting data management"
        end

        if hasReachedObjective and !itHassBeenAWeek then
            strings << ", objective met, #{(7 - timeSinceResetInDays).round(2)} days before reset"
        end

        if !hasReachedObjective and !itHassBeenAWeek then
            strings << ", #{(engine["hours"] - Bank::getValue(engine["capsule"]).to_f/3600).round(2)} hours to go, #{(7 - timeSinceResetInDays).round(2)} days left in period"
        end

        if !hasReachedObjective and itHassBeenAWeek then
            strings << ", late by #{(timeSinceResetInDays-7).round(2)} days"
        end

        strings << ")"
        strings.join()
    end
end





