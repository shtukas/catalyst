
class NxProjects

    # NxProjects::toString(item)
    def self.toString(item)
        "⛵️ #{item["description"]}"
    end

    # NxProjects::level(item)
    def self.level(item)
        valueInHours = Bank1::getValue(item["uuid"]).to_f/3600
        return 0 if valueInHours < 5
        return 1 if valueInHours < 10
        return 2 if valueInHours < 20
        return 3 if valueInHours < 50
        4
    end

    # NxProjects::itemsPerLevel(level)
    def self.itemsPerLevel(level)
        Items::mikuType("NxProject")
            .select{|item| NxProjects::level(item) == level }
    end
end
