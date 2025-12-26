
class Transmute

    # Transmute::transmuteTo(item, targetType)
    def self.transmuteTo(item, targetType)
        if item["mikuType"] == "NxOndate" and targetType == "NxTask" then
            Blades::setAttribute(item["uuid"], "mikuType", "NxTask")
            return
        end
        raise "(error a7093fd4-0236) I do not know how to transmute #{item["mikuType"]} to #{targetType}"
    end
end
