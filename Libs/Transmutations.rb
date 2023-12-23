
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
        mikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", map[item["mikuType"]])
        return if mikuType.nil?
        Transmutations::transmute2(item, mikuType)
        CacheWS::emit("mikutype-has-been-modified:#{item["mikuType"]}")
        CacheWS::emit("mikutype-has-been-modified:#{mikuType}")
    end

    # Transmutations::transmute2(item, targetMikuType)
    def self.transmute2(item, targetMikuType)
        if item["mikuType"] == "NxCruiser" and targetMikuType == "NxTask" then
            if NxCruisers::elements(item).size.size > 0 then
                Cubes::setAttribute(item["uuid"], "mikuType", "NxTask")
                item = Cubes::itemOrNull(item["uuid"])
                puts JSON.pretty_generate(item)
                NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            else
                puts "We cannot trnasmute a NxCruise with non empty cargo. Found #{NxCruisers::elements(item).size} elements"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxMonitor" then
            Cubes::setAttribute(item["uuid"], "mikuType", "NxMonitor")
            item = Cubes::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTask" then
            Cubes::setAttribute(item["uuid"], "mikuType", "NxTask")
            item = Cubes::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxCruiser" then
            core = TxCores::interactivelyMakeNew()
            Cubes::setAttribute(item["uuid"], "engine-0020", core)
            Cubes::setAttribute(item["uuid"], "mikuType", "NxCruiser")
            item = Cubes::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxMonitor" and targetMikuType == "NxCruiser" then
            core = TxCores::interactivelyMakeNew()
            Cubes::setAttribute(item["uuid"], "engine-0020", core)
            Cubes::setAttribute(item["uuid"], "mikuType", "NxCruiser")
            item = Cubes::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxMonitor" and targetMikuType == "NxTask" then
            Cubes::setAttribute(item["uuid"], "mikuType", "NxTask")
            item = Cubes::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxTask" and targetMikuType == "NxMonitor" then
            Cubes::setAttribute(item["uuid"], "mikuType", "NxMonitor")
            return
        end
        if item["mikuType"] == "Wave" and targetMikuType == "NxPatrol" then
            Cubes::setAttribute(item["uuid"], "mikuType", "NxPatrol")
            item = Cubes::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxCruisers::interactivelySelectShipAndAddTo(item["uuid"])
            return
        end
        raise "I do not know how to transmute2 a #{item["mikuType"]} into a #{targetMikuType}"
    end
end