# An engine represent a requirement to do something a certain number of hours 
# per day or per week

class NxEngines

    # NxEngines::makeEngineOrNull()
    def self.makeEngineOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("engine type", ["per-day", "per-week"])
        return nil if type.nil?
        if type == "per-day" then
            hours = LucilleCore::askQuestionAnswerAsString("hours per day ?: ").to_f
            if hours == 0 then
                return nil
            end
            return {
                "type" => "per-day",
                "hours" => hours
            }
        end 
        if type == "per-week" then
            hours = LucilleCore::askQuestionAnswerAsString("hours per week ?: ").to_f
            if hours == 0 then
                return nil
            end
            return {
                "type" => "per-week",
                "hours" => hours
            }
        end 
    end

    # NxEngines::dailyTargetInHours(engine)
    def self.dailyTargetInHours(engine)
        if engine["type"] == "per-day" then
            return engine["hours"]
        end
        if engine["type"] == "per-week" then
            return engine["hours"].to_f/5
        end
    end

    # NxEngines::setEngineAttempt(item)
    def self.setEngineAttempt(item)
        engine = NxEngines::makeEngineOrNull()
        return if engine.nil?
        Blades::setAttribute(item["uuid"], "engine-1437", engine)
    end

    # NxEngines::ratio(item)
    def self.ratio(item)
        if item["engine-1437"].nil? then
            raise "error: item '#{item}' has not engine at engine-1437"
        end
        done = BankDerivedData::recoveredAverageHoursPerDay(item["uuid"])
        target = NxEngines::dailyTargetInHours(engine)
        done.to_f/target
    end

    # NxEngines::engined()
    def self.engined()
        Blades::items().select{|item| item["engine-1437"] }
    end

    # NxEngines::listingItems()
    def self.listingItems()
        NxEngines::engined().select{|item| NxEngines::ratio(item) < 1 }
    end
end
