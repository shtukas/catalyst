
class Transmutation

    # Transmutation::transmute1(item, targetMikuType)
    def self.transmute1(item, targetMikuType)
        return if targetMikuType.nil?
        puts "Transmuting '#{PolyFunctions::toString(item)}' from #{item["mikuType"]} to #{targetMikuType}"
        
        if item["mikuType"] == "NxOnDate" and targetMikuType == "NxTask" then
            NxTasks::performItemPositioning(item["uuid"])
            Items::setAttribute(item["uuid"], "mikuType", "NxTask")
            ListingService::evaluate(item["uuid"])
            return
        end
        if item["mikuType"] == "NxOnDate" and targetMikuType == "NxFloat" then
            Items::setAttribute(item["uuid"], "mikuType", "NxFloat")
            ListingService::evaluate(item["uuid"])
            return
        end
        if item["mikuType"] == "NxOnDate" and targetMikuType == "NxFloat" then
            Items::setAttribute(item["uuid"], "mikuType", "NxFloat")
            ListingService::evaluate(item["uuid"])
            return
        end
        if item["mikuType"] == "NxOnDate" and targetMikuType == "NxTracker" then
            Items::setAttribute(item["uuid"], "mikuType", "NxTracker")
            ListingService::removeEntry(item["uuid"])
            return
        end
        if item["mikuType"] == "NxTask" and targetMikuType == "NxFloat" then
            Items::setAttribute(item["uuid"], "mikuType", "NxFloat")
            ListingService::evaluate(item["uuid"])
            return
        end
        puts "I do not know how to transmute mikuType #{item["mikuType"]} to #{targetMikuType}. Aborting."
        exit
    end

    # Transmutation::transmute2(item)
    def self.transmute2(item)
        targetMikuType = nil
        if item["mikuType"] == "NxTask" then
            targetMikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("MikuType", ["NxFloat", "NxOnDate"])
        end
        if item["mikuType"] == "NxOnDate" then
            targetMikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("MikuType", ["NxTask", "NxTracker"])
        end
        return if targetMikuType.nil?
        Transmutation::transmute1(item, targetMikuType)
    end
end
