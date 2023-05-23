
class Transmutations

    # Transmutations::targetMikuTypes()
    def self.targetMikuTypes()
        ["NxBurner", "NxFire", "NxTask"]
    end

    # Transmutations::interactivelySelectMikuTypeOrNull()
    def self.interactivelySelectMikuTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", Transmutations::targetMikuTypes())
    end

    # Transmutations::setCoordinates(itemuuid)
    def self.setCoordinates(itemuuid)
        optional_parent, optional_position = NxTasks::interactivelyDetermineItemCoordinates()
        if optional_parent then
            Solingen::setAttribute2(item["uuid"], "parent", optional_parent["uuid"])
        end
        if optional_position then
            Solingen::setAttribute2(item["uuid"], "position", optional_position)
        end
    end

    # Transmutations::transmute(item)
    def self.transmute(item)

        sourceType = Solingen::getMandatoryAttribute2(item["uuid"], "mikuType")

        targetMikuType = Transmutations::interactivelySelectMikuTypeOrNull()
        return if targetMikuType.nil?

        if item["mikuType"] == "NxFire" and targetMikuType == "NxTask" then
            Transmutations::setCoordinates(item["uuid"])
            Solingen::setAttribute2(item["uuid"], "mikuType", "NxFire")
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxFire" then
            Transmutations::setCoordinates(item["uuid"])
            Solingen::setAttribute2(item["uuid"], "mikuType", "NxFire")
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxBurner" then
            Transmutations::setCoordinates(item["uuid"])
            Solingen::setAttribute2(item["uuid"], "mikuType", "NxBurner")
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTask" then
            Transmutations::setCoordinates(item["uuid"])
            Solingen::setAttribute2(item["uuid"], "mikuType", "NxTask")
            return
        end

        puts "I do not know how to transmute uuid: #{uuid}, sourceType: #{sourceType} to #{targetMikuType}"
        LucilleCore::pressEnterToContinue()
    end
end