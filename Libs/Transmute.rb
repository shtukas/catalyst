
class Transmute

    # Transmute::transmuteTo(item, targetType)
    def self.transmuteTo(item, targetType)
        if item["mikuType"] == "NxOndate" and targetType == "NxTask" then
            Blades::setAttribute(item["uuid"], "mikuType", "NxTask")
            return
        end
        if item["mikuType"] == "NxToday" and targetType == "NxProject" then
            hours = LucilleCore::askQuestionAnswerAsString("hours per day: ").to_f
            Blades::setAttribute(item["uuid"], "tc-15", hours)
            Blades::setAttribute(item["uuid"], "mikuType", "NxProject")
            return
        end
        raise "(error a7093fd4-0236) I do not know how to transmute #{item["mikuType"]} to #{targetType}"
    end

    # Transmute::transmute(item)
    def self.transmute(item)
        if item["mikuType"] == "NxToday" then
            targetType = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", ["NxProject"])
            if targetType then
                Transmute::transmuteTo(item, targetType)
                return
            end
        end
    end
end
