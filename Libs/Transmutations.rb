
class Transmutations

    # Transmutations::transmute(item)
    def self.transmute(item)
        if item["mikuType"] == "NxOndate" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("target type", ["NxTask"])
            return if option.nil?
            if option == "NxTask" then
                engine = TxEngines::interactivelyMakeNewOrNull()
                return if engine.nil?
                Cubes::setAttribute(item["uuid"], "engine-0916", engine)
                Cubes::setAttribute(item["uuid"], "mikuType", "NxTask")
            end
        end
    end
end
