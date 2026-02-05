
class NxEngines

    # NxEngines::engine_types()
    def self.engine_types()
        [
            "monday-to-friday-work",
            "time-commitment-hours-per-week",
            # "daily-monitoring-do-at-discretion", # deprecated
        ]
    end

    # NxEngines::interactivelySelectEngineTypeOrNull()
    def self.interactivelySelectEngineTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("engine type", NxEngines::engine_types())
    end

    # NxEngines::interactivelyBuildEngineOrNull()
    def self.interactivelyBuildEngineOrNull()
        engine_type = NxEngines::interactivelySelectEngineTypeOrNull()
        return nil if engine_type.nil?
        if engine_type == "monday-to-friday-work" then
            hours = LucilleCore::askQuestionAnswerAsString("daily hours: ").to_f
            return {
                "uuid" => SecureRandom.hex,
                "type" => "monday-to-friday-work",
                "hours-day" => hours
            }
        end
        if engine_type == "time-commitment-hours-per-week" then
            hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
            return {
                "uuid"  => SecureRandom.hex,
                "type"  => "time-commitment-hours-per-week",
                "hours" => hours
            }
        end
        raise "(error: 8d8ba6b2) unknown engine type: #{engine_type}"
    end

    # NxEngines::positionOrNull(item, engine, lowerbound, upperbound)
    def self.positionOrNull(item, engine, lowerbound, upperbound)
        if engine["type"] == "daily-monitoring-do-at-discretion" then
            engine["type"] = "time-commitment-hours-per-week"
            engine["hours"] = 2
        end
        if engine["type"] == "monday-to-friday-work" then
            return nil if ![1,2,3,4,5].include?(Time.new.wday)
            rt = BankDerivedData::recoveredAverageHoursPerDay(engine["uuid"]).to_f
            hours = engine["hours-day"]
            return nil if rt >= hours
            ratio = rt.to_f/hours
            return lowerbound + ratio
        end
        if engine["type"] == "time-commitment-hours-per-week" then
            rt = BankDerivedData::recoveredAverageHoursPerDay(engine["uuid"]).to_f
            day_hours = engine["hours"].to_f/6
            return nil if rt >= day_hours
            ratio = rt.to_f/day_hours
            return lowerbound + ratio
        end
        raise "(error: 23de6207) unknown engine type: #{engine["type"]}"
    end

    # NxEngines::toString(engine)
    def self.toString(engine)
        if engine["type"] == "daily-monitoring-do-at-discretion" then
            engine["type"] = "time-commitment-hours-per-week"
            engine["hours"] = 2
        end
        if engine["type"] == "monday-to-friday-work" then
            rt = BankDerivedData::recoveredAverageHoursPerDay(engine["uuid"])
            return "monday-to-friday-work, rt: #{rt.round(2)} hours, target: #{engine["hours-day"]} hours/day"
        end
        if engine["type"] == "time-commitment-hours-per-week" then
            rt = BankDerivedData::recoveredAverageHoursPerDay(engine["uuid"])
            return "time-commitment-hours-per-week, rt: #{rt.round(2)} hours, target (day): #{engine["hours"].to_f/7}"
        end
        raise "(error: 3a9a7c18) unknown engine type: #{engine["type"]}"
    end

    # NxEngines::suffix(item)
    def self.suffix(item)
        return "" if item["engine-24"].nil?
        " #{NxEngines::toString(item["engine-24"])}".yellow
    end

    # NxEngines::listingItems()
    def self.listingItems()
        Blades::items().select{|item| item["engine-24"] }
    end

    # ------------------
    # Ops

    # NxEngines::setEngine(item)
    def self.setEngine(item)
        if !["NxListing", "NxTask"].include?(item["mikuType"]) then
            puts "We only add engines to NxListings and NxTasks"
            LucilleCore::pressEnterToContinue()
            return item
        end
        engine = NxEngines::interactivelyBuildEngineOrNull()
        return item if engine.nil?
        Blades::setAttribute(item["uuid"], "engine-24", engine)
        Blades::itemOrNull(item["uuid"])
    end
end
