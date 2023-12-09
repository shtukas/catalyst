
class Transmutations

    # Transmutations::transmute(item)
    def self.transmute(item)
        if item["mikuType"] == "NxOndate" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", ["sticky" ,"task"])
            return if option.nil?
            if option == "sticky" then
                DataCenter::setAttribute(item["uuid"], "mikuType", "NxSticky")
                item = DataCenter::itemOrNull(item["uuid"])
                puts JSON.pretty_generate(item)
            end
            if option == "task" then
                DataCenter::setAttribute(item["uuid"], "mikuType", "NxTask")
                item = DataCenter::itemOrNull(item["uuid"])
                puts JSON.pretty_generate(item)
                NxCruisers::interactivelySelectShipAndAddTo(item)
            end
            return
        end
        raise "I do not know how to transmute: #{JSON.pretty_generate(item)}"
    end
end