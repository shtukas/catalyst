
class Transmutation

    # Transmutation::transmute1(item, targetMikuType)
    def self.transmute1(item, targetMikuType)
        return if targetMikuType.nil?
        puts "Transmuting '#{PolyFunctions::toString(item)}' from #{item["mikuType"]} to #{targetMikuType}"
        
        if item["mikuType"] == "NxDated" and targetMikuType == "NxTask" then
            NxTasks::performItemPositioning(item["uuid"])
            Items::setAttribute(item["uuid"], "mikuType", "NxTask")
            ListingService::evaluate(item["uuid"])
            return
        end
        if item["mikuType"] == "NxDated" and targetMikuType == "NxFloat" then
            Items::setAttribute(item["uuid"], "mikuType", "NxFloat")
            ListingService::evaluate(item["uuid"])
            return
        end
        if item["mikuType"] == "NxDated" and targetMikuType == "NxProject" then
            position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
            Items::setAttribute(item["uuid"], "mikuType", "NxProject")
            ListingService::evaluate(item["uuid"])
            return
        end
        if item["mikuType"] == "NxTask" and targetMikuType == "NxDated" then
            datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
            Items::setAttribute(uuid, "date", datetime)
            Items::setAttribute(item["uuid"], "mikuType", "NxDated")
            ListingService::evaluate(item["uuid"])
            return
        end
        if item["mikuType"] == "NxTask" and targetMikuType == "NxFloat" then
            Items::setAttribute(item["uuid"], "mikuType", "NxFloat")
            ListingService::evaluate(item["uuid"])
            return
        end
        if item["mikuType"] == "NxTask" and targetMikuType == "NxProject" then
            Items::setAttribute(item["uuid"], "position-1654", NxProjects::lastPosition() + 1)
            item = Items::setAttribute(item["uuid"], "mikuType", "NxProject")
            ListingService::ensure(item)
            return
        end
        puts "I do not know how to transmute mikuType #{item["mikuType"]} to #{targetMikuType}. Aborting."
        exit
    end

    # Transmutation::transmute2(item)
    def self.transmute2(item)
        targetMikuType = nil
        if item["mikuType"] == "NxDated" then
            targetMikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("MikuType", ["NxProject", "NxFloat", "NxTask"])
        end
        if item["mikuType"] == "NxTask" then
            targetMikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("MikuType", ["NxFloat", "NxDated", "NxProject"])
        end
        return if targetMikuType.nil?
        Transmutation::transmute1(item, targetMikuType)
    end
end
