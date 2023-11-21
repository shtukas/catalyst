
class Transmutations

    # Transmutations::transmute(item)
    def self.transmute(item)
        if item["mikuType"] == "NxOndate" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("target type", ["NxTask"])
            return if option.nil?
            if option == "NxTask" then
                DataCenter::setAttribute(item["uuid"], "mikuType", "NxTask")
                NxTasks::setTaskMode(item)
            end
        end
    end
end
