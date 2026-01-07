
class Transmute

    # Transmute::transmuteTo(item, targetType)
    def self.transmuteTo(item, targetType)
        if item["mikuType"] == "NxOndate" and targetType == "NxTask" then
            Blades::setAttribute(item["uuid"], "mikuType", "NxTask")
            return
        end
        if item["mikuType"] == "NxToday" and targetType == "NxTimeCommitment" then
            hours = LucilleCore::askQuestionAnswerAsString("commitment per day in hours: ").to_f
            Blades::setAttribute(item["uuid"], "tx31", hours)
            Blades::setAttribute(item["uuid"], "mikuType", "NxTimeCommitment")
            return
        end
        raise "(error a7093fd4-0236) I do not know how to transmute #{item["mikuType"]} to #{targetType}"
    end
end
