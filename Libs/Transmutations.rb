
class Transmutations

    # Transmutations::transmute1(item)
    def self.transmute1(item)
        map = {
            "NxOndate"  => ["NxTask", "NxProject"],
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
        if item["mikuType"] == "NxProject" and targetMikuType == "NxTask" then
            if NxProjects::elementsInNaturalOrder(item).size.size > 0 then
                Cubes2::setAttribute(item["uuid"], "mikuType", "NxTask")
                item = Cubes2::itemOrNull(item["uuid"])
                puts JSON.pretty_generate(item)
                NxProjects::interactivelySelectOneAndAddTo(item["uuid"])
            else
                puts "We cannot trnasmute a NxCruise with non empty cargo. Found #{NxProjects::elementsInNaturalOrder(item).size} elements"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTask" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxTask")
            item = Cubes2::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxProjects::interactivelySelectOneAndAddTo(item["uuid"])
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxProject" then
            core = TxCores::interactivelyMakeNewOrNull()
            Cubes2::setAttribute(item["uuid"], "engine-0020", core)
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxProject")
            item = Cubes2::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxProjects::upgradeItemDonations(item)
            return
        end
        if item["mikuType"] == "Wave" and targetMikuType == "NxMission" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxMission")
            Cubes2::setAttribute(item["uuid"], "lastDoneUnixtime", Time.new.to_i)
            item = Cubes2::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxProjects::upgradeItemDonations(item)
            return
        end
        raise "I do not know how to transmute2 a #{item["mikuType"]} into a #{targetMikuType}"
    end
end