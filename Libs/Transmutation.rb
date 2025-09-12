
class Transmutation

    # Transmutation::transmute1(item, targetMikuType)
    def self.transmute1(item, targetMikuType)
        return if targetMikuType.nil?
        puts "Transmuting '#{PolyFunctions::toString(item)}' from #{item["mikuType"]} to #{targetMikuType}"
        if item["mikuType"] == "NxDeadline" and targetMikuType == "NxTask" then
            Items::setAttribute(item["uuid"], "priorityLevel48", PriorityLevels::interactivelySelectOne())
            Items::setAttribute(item["uuid"], "mikuType", "NxTask")
            ListingService::evaluate(item["uuid"])
            return
        end
        if item["mikuType"] == "NxDeadline" and targetMikuType == "NxProject" then
            Items::setAttribute(item["uuid"], "mikuType", "NxProject")
            ListingService::evaluate(item["uuid"])
            return
        end
        if item["mikuType"] == "NxOnDate" and targetMikuType == "NxTask" then
            Items::setAttribute(item["uuid"], "priorityLevel48", PriorityLevels::interactivelySelectOne())
            Items::setAttribute(item["uuid"], "mikuType", "NxTask")
            ListingService::evaluate(item["uuid"])
            return
        end
        if item["mikuType"] == "NxOnDate" and targetMikuType == "NxTracker" then
            Items::setAttribute(item["uuid"], "mikuType", "NxTracker")
            ListingService::removeEntry(item["uuid"])
            return
        end
        if item["mikuType"] == "NxProject" and targetMikuType == "NxDeadline" then
            Items::setAttribute(item["uuid"], "date", CommonUtils::interactivelyMakeADateOrNull())
            Items::setAttribute(item["uuid"], "mikuType", "NxDeadline")
            ListingService::removeEntry(item["uuid"])
            return
        end
        if item["mikuType"] == "NxProject" and targetMikuType == "NxTask" then
            Items::setAttribute(item["uuid"], "priorityLevel48", PriorityLevels::interactivelySelectOne())
            Items::setAttribute(item["uuid"], "mikuType", "NxDeadline")
            ListingService::removeEntry(item["uuid"])
            return
        end
        puts "I do not know how to transmute mikuType #{item["mikuType"]} to #{targetMikuType}. Aborting."
        exit
    end

    # Transmutation::transmute2(item)
    def self.transmute2(item)
        targetMikuType = nil
        if item["mikuType"] == "NxTask" then
            targetMikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("MikuType", ["NxOnDate"])
        end
        if item["mikuType"] == "NxProject" then
            targetMikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("MikuType", ["NxDeadline", "NxTask"])
        end
        if item["mikuType"] == "NxDeadline" then
            targetMikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("MikuType", ["NxTask", "NxProject"])
        end
        if item["mikuType"] == "NxOnDate" then
            targetMikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("MikuType", ["NxTask", "NxTracker"])
        end
        return if targetMikuType.nil?
        Transmutation::transmute1(item, targetMikuType)
    end
end
