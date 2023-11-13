
class Transmutations

    # Transmutations::transmute(item)
    def self.transmute(item)
        if item["mikuType"] == "NxOndate" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("target type", ["NxCurrentProject"])
            return if option.nil?
            if option == "NxCurrentProject" then
                Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxCurrentProject")
                engine = TxEngines::interactivelyMakeNewOrNull()
                if engine then
                    Updates::itemAttributeUpdate(item["uuid"], "engine-0916", engine)
                end
            end
        end
        if item["mikuType"] == "NxTask" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("target type", ["NxCurrentProject"])
            return if option.nil?
            if option == "NxCurrentProject" then
                Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxCurrentProject")
                engine = TxEngines::interactivelyMakeNewOrNull()
                if engine then
                    Updates::itemAttributeUpdate(item["uuid"], "engine-0916", engine)
                end
            end
        end
    end
end
