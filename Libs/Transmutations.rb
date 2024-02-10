
class Transmutations

    # Transmutations::transmute1(item)
    def self.transmute1(item)
        map = {
            "NxOndate"  => ["NxTodo"],
            "Wave"      => ["NxRingworldMission"],
            "NxTodo" => ["NxOrbital"]
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
        if item["mikuType"] == "NxTodo" and targetMikuType == "NxOrbital" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxOrbital")
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTodo" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxTodo")
            item = Cubes2::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            NxTodos::positionItemOnTreeUseDescent(item)
            return
        end
        if item["mikuType"] == "Wave" and targetMikuType == "NxRingworldMission" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxRingworldMission")
            Cubes2::setAttribute(item["uuid"], "lastDoneUnixtime", Time.new.to_i)
            item = Cubes2::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            Catalyst::interactivelySetDonations(item)
            return
        end
        raise "I do not know how to transmute2 a #{item["mikuType"]} into a #{targetMikuType}"
    end
end