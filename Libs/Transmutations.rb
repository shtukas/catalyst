
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

        setTaskEngineCliqueAndPosition = lambda {|item|
            engineuuid = 
                if item["engineuuid"] then
                    item["engineuuid"]
                else
                    engineuuid = TxEngines::interactivelySelectOneUUIDOrNull()
                    Solingen::setAttribute2(item["uuid"], "engineuuid", engineuuid)
                    engineuuid
                end
            engine = Solingen::getItemOrNull(engineuuid)
            NxTasks::setCliqueAndPositionAtEngine(engine, item)
        }

        sourceType = Solingen::getMandatoryAttribute2(item["uuid"], "mikuType")

        targetMikuType = Transmutations::interactivelySelectMikuTypeOrNull()
        return if targetMikuType.nil?

        if item["mikuType"] == "NxDrop" and targetMikuType == "NxBurner" then
            Solingen::setAttribute2(item["uuid"], "mikuType", "NxBurner")
            return
        end

        if item["mikuType"] == "NxDrop" and targetMikuType == "NxFire" then
            Solingen::setAttribute2(item["uuid"], "mikuType", "NxFire")
            return
        end

        if item["mikuType"] == "NxDrop" and targetMikuType == "NxTask" then
            setTaskEngineCliqueAndPosition.call(item)
            Solingen::setAttribute2(item["uuid"], "mikuType", "NxTask")
            return
        end

        if item["mikuType"] == "NxFire" and targetMikuType == "NxTask" then
            setTaskEngineCliqueAndPosition.call(item)
            Solingen::setAttribute2(item["uuid"], "mikuType", "NxTask")
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxBurner" then
            Solingen::setAttribute2(item["uuid"], "mikuType", "NxBurner")
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxFire" then
            Solingen::setAttribute2(item["uuid"], "mikuType", "NxFire")
            return
        end

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTask" then
            setTaskEngineCliqueAndPosition.call(item)
            Solingen::setAttribute2(item["uuid"], "mikuType", "NxTask")
            return
        end

        puts "I do not know how to transmute uuid: #{item["uuid"]}, sourceType: #{sourceType} to #{targetMikuType}"
        LucilleCore::pressEnterToContinue()
    end
end