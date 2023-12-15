
class Transmutations

    # Transmutations::transmute1(item)
    def self.transmute1(item)
        map = {
            "NxOndate"  => ["NxSticky" ,"NxTask", "NxCruiser"],
            "NxTask"    => ["NxMonitor"],
            "NxMonitor" => ["NxTask", "NxCruiser"],
            "NxCruiser" => ["NxTask"],
            "Wave"      => ["NxPatrol"],
        }
        if map[item["mikuType"]].nil? then
            raise "I do not know how to transmute: #{JSON.pretty_generate(item)}"
        end
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", map[item["mikuType"]])
        return if option.nil?
        Transmutations::transmute2(item, option)
    end

    # Transmutations::transmute2(item, targetMikuType)
    def self.transmute2(item, targetMikuType)
        if item["mikuType"] == "NxCruiser" and targetMikuType == "NxTask" then
            if NxCruisers::elements(item).size.size > 0 then
                DataCenter::setAttribute(item["uuid"], "mikuType", "NxTask")
                item = DataCenter::itemOrNull(item["uuid"])
                puts JSON.pretty_generate(item)
                NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            else
                puts "We cannot trnasmute a NxCruise with non empty cargo. Found #{NxCruisers::elements(item).size} elements"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxMonitor" then
            DataCenter::setAttribute(item["uuid"], "mikuType", "NxMonitor")
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
            DataCenter::setAttribute(item["uuid"], "engine-0020", core)
            DataCenter::setAttribute(item["uuid"], "mikuType", "NxCruiser")
            item = DataCenter::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxMonitor" and targetMikuType == "NxCruiser" then
            core = TxCores::interactivelyMakeNew()
            DataCenter::setAttribute(item["uuid"], "engine-0020", core)
            DataCenter::setAttribute(item["uuid"], "mikuType", "NxCruiser")
            item = DataCenter::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxMonitor" and targetMikuType == "NxTask" then
            DataCenter::setAttribute(item["uuid"], "mikuType", "NxTask")
            item = DataCenter::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxTask" and targetMikuType == "NxMonitor" then
            DataCenter::setAttribute(item["uuid"], "mikuType", "NxMonitor")
            return
        end
        if item["mikuType"] == "Wave" and targetMikuType == "NxPatrol" then
            DataCenter::setAttribute(item["uuid"], "mikuType", "NxPatrol")
            item = DataCenter::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            return
        end
        raise "I do not know how to transmute2 a #{item["mikuType"]} into a #{targetMikuType}"
    end
end