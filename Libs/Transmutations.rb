
class Transmutations

    # Transmutations::transmute1(item)
    def self.transmute1(item)
        if item["mikuType"] == "NxOndate" then
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", ["sticky" ,"task", "cruiser"])
            return if option.nil?
            if option == "sticky" then
                Transmutations::transmute2(item, "NxSticky")
            end
            if option == "task" then
                Transmutations::transmute2(item, "NxTask")
            end
            if option == "cruiser" then
                Transmutations::transmute2(item, "NxCruiser")
            end
            return
        end
        raise "I do not know how to transmute: #{JSON.pretty_generate(item)}"
    end

    # Transmutations::transmute2(item, targetMikuType)
    def self.transmute2(item, targetMikuType)
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxSticky" then
            DataCenter::setAttribute(item["uuid"], "mikuType", "NxSticky")
            item = DataCenter::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTask" then
            DataCenter::setAttribute(item["uuid"], "mikuType", "NxTask")
            item = DataCenter::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxCruiser" then
            core = TxCores::interactivelyMakeNew()
            DataCenter::setAttribute(item["uuid"], "engine-0020", [core])
            DataCenter::setAttribute(item["uuid"], "mikuType", "NxCruiser")
            item = DataCenter::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxSticky" and targetMikuType == "NxCruiser" then
            core = TxCores::interactivelyMakeNew()
            DataCenter::setAttribute(item["uuid"], "engine-0020", [core])
            DataCenter::setAttribute(item["uuid"], "mikuType", "NxCruiser")
            item = DataCenter::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            return
        end
        raise "I do not know how to transmute2 a #{item["mikuType"]} into a #{targetMikuType}"
    end
end