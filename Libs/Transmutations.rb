
class Transmutations

    # Transmutations::targetMikuTypes()
    def self.targetMikuTypes()
        ["NxFront", "NxTask", "NxProject"]
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

        if item["mikuType"] == "NxFront" and targetMikuType == "NxTask" then
            DarkEnergy::patch(item["uuid"], "parent", TxCores::interactivelyMakeTx8WithCoreParentOrNull())
            DarkEnergy::patch(item["uuid"], "mikuType", "NxTask")
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxFront" then
            DarkEnergy::patch(item["uuid"], "mikuType", "NxFront")
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTask" then
            DarkEnergy::patch(item["uuid"], "parent", TxCores::interactivelyMakeTx8WithCoreParentOrNull())
            DarkEnergy::patch(item["uuid"], "mikuType", "NxTask")
            return
        end

        puts "I do not know how to transmute uuid: #{item["uuid"]}, sourceType: #{sourceType} to #{targetMikuType}"
        LucilleCore::pressEnterToContinue()
    end

    # Transmutations::transmuteTo(item, targetMikuType)
    def self.transmuteTo(item, targetMikuType)
        return if !LucilleCore::askQuestionAnswerAsBoolean("Confirm transmutation of '#{PolyFunctions::toString(item).green}' to #{targetMikuType.green}: ")
        if targetMikuType == "NxFront" then
            DarkEnergy::patch(item["uuid"], "mikuType", "NxFront")
            item = DarkEnergy::itemOrNull(item["uuid"])
            ListingPositions::interactivelySetPositionAttempt(item)
        end
        if targetMikuType == "NxTask" then
            DarkEnergy::patch(item["uuid"], "parent", TxCores::interactivelyMakeTx8WithCoreParentOrNull())
            DarkEnergy::patch(item["uuid"], "mikuType", "NxTask")
        end
        if targetMikuType == "NxProject" then
            engine = TxEngines::interactivelyMakeEngine()
            DarkEnergy::patch(item["uuid"], "engine", engine)
            DarkEnergy::patch(item["uuid"], "parent", TxCores::interactivelyMakeTx8WithCoreParentOrNull())
            DarkEnergy::patch(item["uuid"], "mikuType", "NxProject")
        end
    end
end