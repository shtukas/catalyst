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
        Items::setAttribute(item["uuid"], "engine-1437", engine)
    end

    # NxEngines::ratio(item, simulation_timespan = 0)
    def self.ratio(item, simulation_timespan = 0)
        if item["engine-1437"].nil? then
            raise "error: item '#{item}' has not engine at engine-1437"
        end
        done = BankDerivedData::recoveredAverageHoursPerDay(item["uuid"], simulation_timespan)
        target = NxEngines::dailyTargetInHours(item["engine-1437"])
        done.to_f/target
    end

    # NxEngines::missing_timespan_for_today(item)
    def self.missing_timespan_for_today(item)
        raise "[error 9944B5C8]" if item["engine-1437"].nil?
        return 0 if NxEngines::ratio(item) >= 1
        timespan = 0 
        loop {
            timespan += 600
            break if NxEngines::ratio(item, timespan) >= 1
        }
        timespan
    end

    # NxEngines::engined()
    def self.engined()
        Items::items().select{|item| item["engine-1437"] }
    end

    # NxEngines::listingItems()
    def self.listingItems()
        # Version 1
        # NxEngines::engined().select{|item| NxEngines::ratio(item) < 1 }.sort_by{|item| NxEngines::ratio(item) }

        # Version 2
        NxEngines::engined().each{|item|
            needed = NxEngines::missing_timespan_for_today(item) -  NxEngineDelegate::total_capacity_for_targetuuid(item["uuid"])
            next if needed <= 0
            5.times {
                capacity = needed.to_f/5
                puts "issuing delegate for #{PolyFunctions::toString(item)}, capacity: #{capacity}"
                LucilleCore::pressEnterToContinue()
                NxEngineDelegate::issue(item["uuid"], capacity)
            }
        }
    end

    # NxEngines::interactivelySelectEnginedOrNull()
    def self.interactivelySelectEnginedOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("engined", NxEngines::engined(), lambda{|item| PolyFunctions::toString(item) })
    end

    # NxEngines::engineToString(item)
    def self.engineToString(item)
        "(engine ratio: #{(100 * NxEngines::ratio(item)).round(2)} %)"
    end

    # NxEngines::suffix(item)
    def self.suffix(item)
        if item["engine-1437"] then
            return " #{NxEngines::engineToString(item)}".green
        end
        ""
    end
end
