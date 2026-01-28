
class NxEngines

    # NxEngines::engine_types()
    def self.engine_types()
        [
            "daily-monitoring-do-at-discretion",
            "monday-to-friday-work"
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
        if engine_type == "daily-monitoring-do-at-discretion" then
            return {
                "uuid" => SecureRandom.hex,
                "type" => "daily-monitoring-do-at-discretion"
            }
        end
        if engine_type == "monday-to-friday-work" then
            hours = LucilleCore::askQuestionAnswerAsString("daily hours: ").to_f
            return {
                "uuid" => SecureRandom.hex,
                "type" => "monday-to-friday-work",
                "hours-day" => hours
            }
        end
        raise "(error: 8d8ba6b2) unknown engine type: #{engine_type}"
    end

    # NxEngines::positionOrNull(item, engine)
    def self.positionOrNull(item, engine)
        # 2.000 -> 3.000
        if engine["type"] == "daily-monitoring-do-at-discretion" then
            return 2.000
        end
        if engine["type"] == "monday-to-friday-work" then
            return nil if ![1,2,3,4,5].include?(Time.new.wday)
            done_hours = BankDerivedData::recoveredAverageHoursPerDay(engine["uuid"]).to_f/3600
            target_hours = engine["hours-day"]
            return nil if done_hours >= target_hours
            ratio = done_hours.to_f/target_hours
            return 2.000 + ratio
        end
        raise "(error: 23de6207) unknown engine type: #{engine["type"]}"
    end

    # NxEngines::toString(engine)
    def self.toString(engine)
        if engine["type"] == "daily-monitoring-do-at-discretion" then
            return "daily-monitoring-do-at-discretion, work and dismiss"
        end
        if engine["type"] == "monday-to-friday-work" then
            done_hours = BankDerivedData::recoveredAverageHoursPerDay(engine["uuid"])
            return "monday-to-friday-work, done: #{done_hours.round(2)} hours, target: #{engine["hours-day"]} hours/day, work and dismiss"
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
            return
        end
        engine = NxEngines::interactivelyBuildEngineOrNull()
        return if engine.nil?
        Blades::setAttribute(item["uuid"], "engine-24", engine)
    end
end
