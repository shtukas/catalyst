
class Transmutations

    # Transmutations::transmute1(item)
    def self.transmute1(item)
        map = {
            "NxOndate"  => ["NxMonitor" ,"NxTask", "NxBlock"],
            "NxTask"    => ["NxMonitor"],
            "NxMonitor" => ["NxTask", "NxBlock"],
            "NxBlock" => ["NxTask"],
            "Wave"      => ["NxPatrol"],
        }
        if map[item["mikuType"]].nil? then
            raise "I do not know how to transmute: #{JSON.pretty_generate(item)}"
        end
        mikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", map[item["mikuType"]])
        return if mikuType.nil?
        Transmutations::transmute2(item, mikuType)
    end

    # Transmutations::transmute2(item, targetMikuType)
    def self.transmute2(item, targetMikuType)
        if item["mikuType"] == "NxBlock" and targetMikuType == "NxTask" then
            if NxBlocks::elementsInNaturalCruiseOrder(item).size.size > 0 then
                Cubes::setAttribute(item["uuid"], "mikuType", "NxTask")
                item = Cubes::itemOrNull(item["uuid"])
                puts JSON.pretty_generate(item)
                NxBlocks::interactivelySelectBlockAndAddTo(item["uuid"])
            else
                puts "We cannot trnasmute a NxCruise with non empty cargo. Found #{NxBlocks::elementsInNaturalCruiseOrder(item).size} elements"
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
            NxBlocks::interactivelySelectBlockAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxBlock" then
            core = TxCores::interactivelyMakeNew()
            Cubes::setAttribute(item["uuid"], "engine-0020", core)
            Cubes::setAttribute(item["uuid"], "mikuType", "NxBlock")
            item = Cubes::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxBlocks::interactivelySelectBlockAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxMonitor" and targetMikuType == "NxBlock" then
            core = TxCores::interactivelyMakeNew()
            Cubes::setAttribute(item["uuid"], "engine-0020", core)
            Cubes::setAttribute(item["uuid"], "mikuType", "NxBlock")
            item = Cubes::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxBlocks::interactivelySelectBlockAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxMonitor" and targetMikuType == "NxTask" then
            Cubes::setAttribute(item["uuid"], "mikuType", "NxTask")
            item = Cubes::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxBlocks::interactivelySelectBlockAndAddTo(item["uuid"])
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
            NxBlocks::interactivelySelectBlockAndAddTo(item["uuid"])
            return
        end
        raise "I do not know how to transmute2 a #{item["mikuType"]} into a #{targetMikuType}"
    end
end