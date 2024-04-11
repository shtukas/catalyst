
class Transmutations

    # Transmutations::transmute1(item)
    def self.transmute1(item)
        map = {
            "NxOndate"  => ["NxTodo", "NxSingularNonWorkQuest", "NxFloat"],
            "Wave"      => ["NxRingworldMission"],
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

        if item["mikuType"] == "NxOndate" and targetMikuType == "NxTodo" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxTodo")
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["set hours", "position"])
            if option.nil? then
                option = "position"
            end
            if option == "set hours" then
                hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
                hours = (hours == 0) ? 1 : hours
                Cubes2::setAttribute(item["uuid"], "hours", hours)
                return
            end
            if option == "position" then
                parent = NxTodos::interactivelySelectOrphanOrNull()
                return if parent.nil?
                position = Catalyst::interactivelySelectPositionInParent(parent)
                Cubes2::setAttribute(todo["uuid"], "global-positioning", position)
                return
            end
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxSingularNonWorkQuest" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxSingularNonWorkQuest")
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxFloat" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxFloat")
            return
        end
        if item["mikuType"] == "Wave" and targetMikuType == "NxRingworldMission" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxRingworldMission")
            Cubes2::setAttribute(item["uuid"], "lastDoneUnixtime", Time.new.to_i)
            item = Cubes2::itemOrNull(item["uuid"])
            puts JSON.pretty_generate(item)
            Catalyst::interactivelySetDonation(item)
            return
        end
        raise "I do not know how to transmute2 a #{item["mikuType"]} into a #{targetMikuType}"
    end
end