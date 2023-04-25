
class TxEngines

    # TxEngines::interactivelySelectEngineTypeOrNull()
    def self.interactivelySelectEngineTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("engine type", ["null (default)", "daily-recovery-time", "weekly-time"])
    end

    # TxEngines::interactivelyMakeEngineOrDefault(uuid = nil)
    def self.interactivelyMakeEngineOrDefault(uuid = nil)
        uuid = uuid || SecureRandom.hex
        type = TxEngines::interactivelySelectEngineTypeOrNull()
        if (type.nil? or type == "null (default)") then
            return TxEngines::defaultEngine(uuid)
        end
        if type == "daily-recovery-time" then
            return {
                "uuid"  => uuid,
                "type"  => "daily-recovery-time",
                "hours" => LucilleCore::askQuestionAnswerAsString("hours: ").to_f
            }
        end
        if type == "weekly-time" then
            return {
                "uuid"          => uuid, # used for the completion ratio computation
                "type"          => "weekly-time",
                "hours"         => LucilleCore::askQuestionAnswerAsString("hours: ").to_f,
                "lastResetTime" => 0,
                "capsule"       => SecureRandom.hex # used for the time management
            }
        end
        raise "Houston (39), we have a problem."
    end

    # TxEngines::defaultEngine(uuid = nil)
    def self.defaultEngine(uuid = nil)
        uuid = uuid || SecureRandom.hex
        {
            "uuid"          => uuid,
            "type"          => "daily-recovery-time",
            "hours"         => 1,
            "lastResetTime" => Time.new.to_i
        }
    end

    # TxEngines::interactivelyMakeEngine(uuid = nil)
    def self.interactivelyMakeEngine(uuid = nil)
        engine = TxEngines::interactivelyMakeEngineOrDefault(uuid = nil)
        return engine if engine
        puts "using default engine"
        TxEngines::defaultEngine(uuid)
    end

    # TxEngines::completionRatio(engine)
    def self.completionRatio(engine)
        if engine["type"] == "one sitting" then
            engine = TxEngines::defaultEngine(engine["uuid"])
        end
        if engine["type"] == "daily-recovery-time" then
            return (BankUtils::recoveredAverageHoursPerDay(engine["uuid"]))/engine["hours"]*3600
        end
        if engine["type"] == "weekly-time" then
            # if completed, we return the highest of both completion ratios
            # if not completed, we return the lowest
            day_completion_ratio = BankCore::getValueAtDate(engine["uuid"], CommonUtils::today()).to_f/(engine["hours"].to_f/5)
            period_completion_ratio = BankCore::getValue(engine["capsule"]).to_f/(engine["hours"]*3600)
            return [day_completion_ratio, period_completion_ratio].max
        end
        raise "could not TxEngines::completionRatio(engine) for engine: #{engine}"
    end

    # TxEngines::updateEngineOrNull(description, engine)
    def self.updateEngineOrNull(description, engine)
        if engine["type"] == "one sitting" then
            engine = TxEngines::defaultEngine(engine["uuid"])
        end
        if engine["type"] == "daily-recovery-time" then
            return nil
        end
        if engine["type"] == "weekly-time" then
            return nil if BankCore::getValue(engine["capsule"]).to_f/3600 < engine["hours"]
            return nil if (Time.new.to_i - engine["lastResetTime"]) < 86400*7
            if BankCore::getValue(engine["capsule"]).to_f/3600 > 1.5*engine["hours"] then
                overflow = 0.5*engine["hours"]*3600
                puts "I am about to smooth engine: #{engine}, overflow: #{(overflow.to_f/3600).round(2)} hours (for description: #{description})"
                LucilleCore::pressEnterToContinue()
                NxTimePromises::smooth_effect(engine["capsule"], -overflow, 20)
                return nil
            end
            puts "I am about to reset engine: #{engine} (for description: #{description})"
            LucilleCore::pressEnterToContinue()
            BankCore::put(engine["capsule"], -engine["hours"]*3600)
            engine["lastResetTime"] = Time.new.to_i
            return engine
        end
        raise "could not TxEngines::updateEngineOrNull(description, engine) for engine: #{engine}"
    end

    # TxEngines::engineMaintenanceOrNothing(item)
    def self.engineMaintenanceOrNothing(item)
        engine = TxEngines::updateEngineOrNull(item["description"], item["engine"])
        if engine then
            item["engine"] = engine
            puts "New item after engine update:"
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
        end
        item
    end

    # TxEngines::toString(engine)
    def self.toString(engine)
        if engine["type"] == "one sitting" then
            engine = TxEngines::defaultEngine(engine["uuid"])
        end
        if engine["type"] == "daily-recovery-time" then
            return "(engine: #{BankUtils::recoveredAverageHoursPerDay(engine["uuid"]).round(2)} of daily #{engine["hours"]} hours)"
        end
        if engine["type"] == "weekly-time" then
            strings = []
            strings << "(engine: #{(BankCore::getValueAtDate(engine["uuid"], CommonUtils::today()).to_f/3600).round(2)} of today #{engine["hours"].to_f/5} hours"

            strings << ", #{(BankCore::getValue(engine["capsule"]).to_f/3600).round(2)} hours of weekly #{engine["hours"]}"

            hasReachedObjective = BankCore::getValue(engine["capsule"]) >= engine["hours"]*3600
            timeSinceResetInDays = (Time.new.to_i - engine["lastResetTime"]).to_f/86400
            itHassBeenAWeek = timeSinceResetInDays >= 7

            if hasReachedObjective and itHassBeenAWeek then
                strings << ", awaiting data management"
            end

            if hasReachedObjective and !itHassBeenAWeek then
                strings << ", objective met, #{(7 - timeSinceResetInDays).round(2)} days before reset"
            end

            if !hasReachedObjective and !itHassBeenAWeek then
                strings << ", #{(engine["hours"] - BankCore::getValue(engine["capsule"]).to_f/3600).round(2)} hours to go, #{(7 - timeSinceResetInDays).round(2)} days left in period"
            end

            if !hasReachedObjective and itHassBeenAWeek then
                strings << ", late by #{(timeSinceResetInDays-7).round(2)} days"
            end

            strings << ")"
            return strings.join()
        end
        raise "could not TxEngines::toString(engine) for engine: #{engine}"
    end
end