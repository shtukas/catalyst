
class NxEngines

    # NxEngines::engine_types()
    def self.engine_types()
        [
            "daily-monitoring-do-at-discretion"
        ]
    end

    # NxEngines::interactivelySelectEngineTypeOrNull()
    def self.interactivelySelectEngineTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("engine type", NxEngines::engine_types())
    end

    # NxEngines::interactivelyBuildEngineOrNull()
    def self.interactivelyBuildEngineOrNull()
        engine_type = NxEngines::interactivelySelectEngineTypeOrNull()
        return nil if engine_type
        if engine_type == "daily-monitoring-do-at-discretion" then
            return {
                "type" => "daily-monitoring-do-at-discretion"
            }
        end
        raise "(error: 8d8ba6b2) unknown engine type: #{engine_type}"
    end

    # NxEngines::position(item, engine)
    def self.position(item, engine)
        2.100
    end

    # NxEngines::listingItems()
    def self.listingItems()
        Blades::items().select{|item| item["engine-24"] }
    end
end
