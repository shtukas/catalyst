
class Transmutations

    # Transmutations::transmute1(item)
    def self.transmute1(item)
        map = {
            "NxOndate"  => ["NxTodo", "NxFloat"],
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
                NxThreads::interactivelySetParent(item)
                return
            end
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikuType == "NxFloat" then
            Cubes2::setAttribute(item["uuid"], "mikuType", "NxFloat")
            return
        end
        raise "I do not know how to transmute2 a #{item["mikuType"]} into a #{targetMikuType}"
    end
end