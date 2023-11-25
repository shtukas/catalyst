
class Transmutations

    # Transmutations::transmute(item)
    def self.transmute(item)
        if item["mikuType"] == "NxOndate" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("target type", ["NxTask", "NxSticky"])
            return if option.nil?
            if option == "NxTask" then
                DataCenter::setAttribute(item["uuid"], "mikuType", "NxTask")
                NxShips::interactivelySelectShipAndAddTo(item)
            end
            if option == "NxSticky" then
                DataCenter::setAttribute(item["uuid"], "mikuType", "NxSticky")
            end
        end
    end
end
