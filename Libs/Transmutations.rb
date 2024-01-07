
class Transmutations

    # Transmutations::transmute1(item)
    def self.transmute1(item)
        map = {
            "NxOndate"  => ["NxMonitor" ,"NxTask", "NxListing"],
            "NxTask"    => ["NxMonitor"],
            "NxMonitor" => ["NxTask", "NxListing"],
            "NxListing"   => ["NxTask"],
            "Wave"      => ["NxMission"],
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
        if item["mikuType"] == "NxListing" and targetMikuType == "NxTask" then
            if NxListings::elementsInNaturalOrder(item).size.size > 0 then
                Cubes2::setAttribute(item["uuid"], "mikuType", "NxTask")
                item = Cubes2::itemOrNull(item["uuid"])
                puts JSON.pretty_generate(item)
                NxListings::interactivelySelectOneAndAddTo(item["uuid"])
            else
                puts "We cannot trnasmute a NxCruise with non empty cargo. Found #{NxListings::elementsInNaturalOrder(item).size} elements"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxMonitor" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxMonitor")
            item = Cubes2::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTask" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxTask")
            item = Cubes2::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxListings::interactivelySelectOneAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxListing" then
            core = TxCores::interactivelyMakeNew()
            Cubes2::setAttribute(item["uuid"], "engine-0020", core)
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxListing")
            item = Cubes2::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxListings::interactivelySelectOneAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxMonitor" and targetMikuType == "NxListing" then
            core = TxCores::interactivelyMakeNew()
            Cubes2::setAttribute(item["uuid"], "engine-0020", core)
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxListing")
            item = Cubes2::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxListings::interactivelySelectOneAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxMonitor" and targetMikuType == "NxTask" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxTask")
            item = Cubes2::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxListings::interactivelySelectOneAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxTask" and targetMikuType == "NxMonitor" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxMonitor")
            return
        end
        if item["mikuType"] == "Wave" and targetMikuType == "NxMission" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxMission")
            Cubes2::setAttribute(item["uuid"], "lastDoneUnixtime", Time.new.to_i)
            item = Cubes2::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxListings::interactivelySelectOneAndAddTo(item["uuid"])
            return
        end
        raise "I do not know how to transmute2 a #{item["mikuType"]} into a #{targetMikuType}"
    end
end