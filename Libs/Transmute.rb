
class Transmute

    # Transmute::transmuteTo(item, targetType) # updated item
    def self.transmuteTo(item, targetType)
        if item["mikuType"] == "NxOndate" and targetType == "NxTask" then
            Nx38s::setMembership(item, {
                "uuid"     => "a18c3b3f-e2d2-48a5-9394-dcb9870e51eb",
                "name"     => "Infinity",
                "position" => rand * 1000
            })

            Blades::setAttribute(item["uuid"], "mikuType", "NxTask")
            return Blades::itemOrNull(item["uuid"])
        end
        raise "(error a7093fd4-0236) I do not know how to transmute #{item["mikuType"]} to #{targetType}"
    end

    # Transmute::transmute(item)
    def self.transmute(item)
        if item["mikuType"] == "NxToday" then
            targetType = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", [""])
            if targetType then
                Transmute::transmuteTo(item, targetType)
                return
            end
        end
    end
end
