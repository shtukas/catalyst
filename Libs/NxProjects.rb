
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

    # NxProjects::itemToAccountingParentUUID(item)
    def self.itemToAccountingParentUUID(item)
        level = NxProjects::level(item)
        return "5bb75e03-eb92-4f10-b816-63f231c4d548" if level == 0 # NxProjects Level 0
        return "26bb2eb2-6ba4-4182-a286-e4afafa75098" if level == 1 # NxProjects Level 1
        return "5c4cfd8f-6f69-4575-9d1b-bb461a601c4b" if level == 2 # NxProjects Level 2
        return "e8116c6d-558e-4e35-818e-419bffe623c9" if level == 3 # NxProjects Level 3
        return "090446d4-9372-4dce-b59d-b4fc02813b3c" if level == 4 # NxProjects Level 4
    end
end
