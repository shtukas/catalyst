
class Transmutations

    # Transmutations::targetMikuTypes()
    def self.targetMikuTypes()
        ["NxFire", "NxTask"]
    end

    # Transmutations::interactivelySelectMikuTypeOrNull()
    def self.interactivelySelectMikuTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", Transmutations::targetMikuTypes())
    end

    # Transmutations::transmute(item)
    def self.transmute(item)
        sourceType = Solingen::getMandatoryAttribute2(item["uuid"], "mikuType")

        targetMikuType = Transmutations::interactivelySelectMikuTypeOrNull()
        return if targetMikuType.nil?

        if item["mikuType"] == "NxFire" and targetMikuType == "NxTask" then
            Solingen::setAttribute2(uuid, "engine", TxEngines::interactivelyMakeEngineOrDefault())
            Solingen::setAttribute2(uuid, "boarduuid", NxBoards::interactivelySelectBoarduuidOrNull())
            Solingen::setAttribute2(uuid, "mikuType", "NxFire")

            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxFire" then
            Solingen::setAttribute2(uuid, "boarduuid", NxBoards::interactivelySelectBoarduuidOrNull())
            Solingen::setAttribute2(uuid, "mikuType", "NxFire")
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTask" then
            board    = NxBoards::interactivelySelectOneOrNull()
            position = NxTasksPositions::decidePositionAtOptionalBoard(board)
            engine   = TxEngines::interactivelyMakeEngineOrDefault()
            Solingen::setAttribute2(uuid, "boarduuid", board ? board["uuid"] : nil)
            Solingen::setAttribute2(uuid, "position", position)
            Solingen::setAttribute2(uuid, "engine", engine)
            Solingen::setAttribute2(uuid, "mikuType", "NxTask")
            return
        end

        puts "I do not know how to transmute uuid: #{uuid}, sourceType: #{sourceType} to #{targetMikuType}"
        LucilleCore::pressEnterToContinue()
    end
end