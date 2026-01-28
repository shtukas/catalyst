
class Transmute

    # Transmute::transmuteTo(item, targetType) # updated item
    def self.transmuteTo(item, targetType)
        if item["mikuType"] == "NxOndate" and targetType == "NxTask" then
            ListingParenting::setMembership(item, NxListings::architectNx38())
            Blades::setAttribute(item["uuid"], "engine-24", NxEngines::interactivelyBuildEngineOrNull())
            Blades::setAttribute(item["uuid"], "mikuType", "NxTask")
            return Blades::itemOrNull(item["uuid"])
        end
        if item["mikuType"] == "NxToday" and targetType == "NxTask" then
            ListingParenting::setMembership(item, NxListings::architectNx38())
            Blades::setAttribute(item["uuid"], "engine-24", NxEngines::interactivelyBuildEngineOrNull())
            Blades::setAttribute(item["uuid"], "mikuType", "NxTask")
            return Blades::itemOrNull(item["uuid"])
        end
        if item["mikuType"] == "Float" and targetType == "NxTask" then
            ListingParenting::setMembership(item, NxListings::architectNx38())
            Blades::setAttribute(item["uuid"], "engine-24", NxEngines::interactivelyBuildEngineOrNull())
            Blades::setAttribute(item["uuid"], "mikuType", "NxTask")
            return Blades::itemOrNull(item["uuid"])
        end
        raise "(error a7093fd4-0236) I do not know how to transmute #{item["mikuType"]} to #{targetType}"
    end

    # Transmute::transmute(item)
    def self.transmute(item)
        mapping = {
            "NxToday" => ["NxTask"],
            "NxOndate" => ["NxTask"],
            "Float" => ["NxTask"],
        }
        targetType = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", mapping[item["mikuType"]])
        if targetType then
            item = PolyActions::editDescription(item)
            Transmute::transmuteTo(item, targetType)
            return
        end
    end
end
