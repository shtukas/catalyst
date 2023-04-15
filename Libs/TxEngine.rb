
class TxEngines

    # TxEngines::interactivelySelectEngineTypeOrNull()
    def self.interactivelySelectEngineTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("engine type", ["daily-time", "daily-recovery-time", "weekly-time"])
    end

    # TxEngines::interactivelyMakeEngineOrNull(uuid = nil)
    def self.interactivelyMakeEngineOrNull(uuid = nil)
        uuid = uuid || SecureRandom.hex
        type = TxEngines::interactivelySelectEngineTypeOrNull()
        return nil if type.nil?
        hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
        {
            "uuid"          => uuid,
            "type"          => type,
            "hours"         => hours,
            "lastResetTime" => Time.new.to_i
        }
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
        engine = TxEngines::interactivelyMakeEngineOrNull(uuid = nil)
        return engine if engine
        puts "using default engine"
        TxEngines::defaultEngine(uuid)
    end

    # TxEngines::completionRatio(engine)
    def self.completionRatio(engine)
        if engine["type"] == "daily-time" then
            doneTodayInHours = BankCore::getValueAtDate(engine["uuid"], CommonUtils::today()).to_f/3600
            return doneTodayInHours.to_f/engine["hours"]
        end
        if engine["type"] == "daily-recovery-time" then
            return (BankUtils::recoveredAverageHoursPerDay(engine["uuid"]))/engine["hours"]
        end
        if engine["type"] == "weekly-time" then
            dailyDone = BankCore::getValueAtDate(engine["uuid"], CommonUtils::today()).to_f/3600
            dailyIdeal = engine["hours"].to_f/5
            return dailyDone.to_f/dailyIdeal
        end
        raise "could not TxEngines::completionRatio(engine) for engine: #{engine}"
    end

    # TxEngines::updateEngineOrNull(description, engine)
    def self.updateEngineOrNull(description, engine)
        if engine["type"] == "daily-time" then
            return nil
        end
        if engine["type"] == "daily-recovery-time" then
            return nil
        end
        if engine["type"] == "weekly-time" then
            return nil if BankCore::getValue(engine["uuid"]).to_f/3600 < engine["hours"]
            return nil if (Time.new.to_i - engine["lastResetTime"]) < 86400*7
            if BankCore::getValue(engine["uuid"]).to_f/3600 > 1.5*engine["hours"] then
                overflow = 0.5*engine["hours"]*3600
                puts "I am about to smooth engine: #{engine}, overflow: #{(overflow.to_f/3600).round(2)} hours (for description: #{description})"
                LucilleCore::pressEnterToContinue()
                NxTimePromises::smooth_effect(engine["uuid"], -overflow, 20)
            end
            puts "I am about to reset engine: #{engine} (for description: #{description})"
            LucilleCore::pressEnterToContinue()
            BankCore::put(engine["uuid"], -engine["hours"]*3600)
            engine["lastResetTime"] = Time.new.to_i
            return engine
        end
        raise "could not TxEngines::updateEngineOrNull(description, engine) for engine: #{engine}"
    end

    # TxEngines::updateItemOrNothing(item)
    def self.updateItemOrNothing(item)
        return item if item["engine"].nil?
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
        if engine["type"] == "daily-time" then
            return "(engine: #{(TxEngines::completionRatio(engine)*100).round(2)} %)"
        end
        if engine["type"] == "daily-recovery-time" then
            return "(engine: #{(TxEngines::completionRatio(engine)*100).round(2)} %)"
        end
        if engine["type"] == "weekly-time" then
            strings = []
            strings << "(engine: #{(TxEngines::completionRatio(engine)*100).round(2)} %"

            strings << ", #{(BankCore::getValue(engine["uuid"]).to_f/3600).round(2)} hours of #{engine["hours"]}"

            hasReachedObjective = BankCore::getValue(engine["uuid"]) >= engine["hours"]*3600
            timeSinceResetInDays = (Time.new.to_i - engine["lastResetTime"]).to_f/86400
            itHassBeenAWeek = timeSinceResetInDays >= 7

            if hasReachedObjective and itHassBeenAWeek then
                strings << ", awaiting data management"
            end

            if hasReachedObjective and !itHassBeenAWeek then
                strings << ", objective met, #{(7 - timeSinceResetInDays).round(2)} days before reset"
            end

            if !hasReachedObjective and !itHassBeenAWeek then
                strings << ", #{(engine["hours"] - BankCore::getValue(engine["uuid"]).to_f/3600).round(2)} hours to go, #{(7 - timeSinceResetInDays).round(2)} days left in period"
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