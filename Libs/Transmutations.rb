
class Transmutations

    # Transmutations::targetMikuTypes()
    def self.targetMikuTypes()
        ["NxBurner", "NxFire", "NxTask"]
    end

    # Transmutations::interactivelySelectMikuTypeOrNull()
    def self.interactivelySelectMikuTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", Transmutations::targetMikuTypes())
    end

    # Transmutations::transmute(item)
    def self.transmute(item)

        sourceType = DarkEnergy::read(item["uuid"], "mikuType")

        targetMikuType = Transmutations::interactivelySelectMikuTypeOrNull()
        return if targetMikuType.nil?

        if item["mikuType"] == "NxDrop" and targetMikuType == "NxBurner" then
            DarkEnergy::patch(item["uuid"], "mikuType", "NxBurner")
            return
        end

        if item["mikuType"] == "NxDrop" and targetMikuType == "NxFire" then
            DarkEnergy::patch(item["uuid"], "mikuType", "NxFire")
            return
        end

        if item["mikuType"] == "NxDrop" and targetMikuType == "NxTask" then
            coreuuid, position = NxTasks::coordinates(nil)
            DarkEnergy::patch(item["uuid"], "coreuuid", coreuuid)
            DarkEnergy::patch(item["uuid"], "position", position)
            DarkEnergy::patch(item["uuid"], "mikuType", "NxTask")
            return
        end

        if item["mikuType"] == "NxFire" and targetMikuType == "NxTask" then
            coreuuid, position = NxTasks::coordinates(nil)
            DarkEnergy::patch(item["uuid"], "coreuuid", coreuuid)
            DarkEnergy::patch(item["uuid"], "position", position)
            DarkEnergy::patch(item["uuid"], "mikuType", "NxTask")
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxBurner" then
            DarkEnergy::patch(item["uuid"], "mikuType", "NxBurner")
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxFire" then
            DarkEnergy::patch(item["uuid"], "mikuType", "NxFire")
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTask" then
            coreuuid, position = NxTasks::coordinates(nil)
            DarkEnergy::patch(item["uuid"], "coreuuid", coreuuid)
            DarkEnergy::patch(item["uuid"], "position", position)
            DarkEnergy::patch(item["uuid"], "mikuType", "NxTask")
            return
        end

        puts "I do not know how to transmute uuid: #{item["uuid"]}, sourceType: #{sourceType} to #{targetMikuType}"
        LucilleCore::pressEnterToContinue()
    end
end