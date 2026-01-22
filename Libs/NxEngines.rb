
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
                "type" => "daily-monitoring-do-at-discretion"
            }
        end
        if engine_type == "monday-to-friday-work" then
            hours = LucilleCore::askQuestionAnswerAsString("daily hours: ").to_f
            return {
                "type" => "monday-to-friday-work",
                "hours-day" => hours
            }
        end
        raise "(error: 8d8ba6b2) unknown engine type: #{engine_type}"
    end

    # NxEngines::position(item, engine)
    def self.position(item, engine)
        if engine["type"] == "daily-monitoring-do-at-discretion" then
            return 2.000
        end
        if engine["type"] == "monday-to-friday-work" then
            return 2.100
        end
        raise "(error: 23de6207) unknown engine type: #{engine["type"]}"
    end

    # NxEngines::toString(engine)
    def self.toString(engine)
        if engine["type"] == "daily-monitoring-do-at-discretion" then
            return "daily-monitoring-do-at-discretion"
        end
        if engine["type"] == "monday-to-friday-work" then
            return "monday-to-friday-work, #{engine["hours-day"]} hours"
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
end
