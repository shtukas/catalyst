
class Transmutation

    # Transmutation::transmute1(item, targetMikuType)
    def self.transmute1(item, targetMikuType)
        return if targetMikuType.nil?
        puts "Transmuting '#{PolyFunctions::toString(item)}' from #{item["mikuType"]} to #{targetMikuType}"
        
        if item["mikuType"] == "NxDated" and targetMikuType == "NxTask" then
            nx1949 = NxTasks::performItemPositioning(item)
            Operations::registerChildInParent(nx1949["parentuuid"], uuid, nx1949["position"])
            Items::setAttribute(item["uuid"], "mikuType", "NxTask")
            return
        end
        if item["mikuType"] == "NxDated" and targetMikuType == "NxFloat" then
            Items::setAttribute(item["uuid"], "mikuType", "NxFloat")
            return
        end
        if item["mikuType"] == "NxTask" and targetMikuType == "NxDated" then
            datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
            Items::setAttribute(uuid, "date", datetime)
            Items::setAttribute(item["uuid"], "mikuType", "NxDated")
            return
        end
        if item["mikuType"] == "NxTask" and targetMikuType == "NxFloat" then
            Items::setAttribute(item["uuid"], "mikuType", "NxFloat")
            return
        end
        puts "I do not know how to transmute mikuType #{item["mikuType"]} to #{targetMikuType}. Aborting."
        exit
    end

    # Transmutation::transmute2(item)
    def self.transmute2(item)
        targetMikuType = nil
        if item["mikuType"] == "NxDated" then
            targetMikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("MikuType", ["NxTask", "NxFloat"])
        end
        if item["mikuType"] == "NxTask" then
            targetMikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("MikuType", ["NxFloat"])
        end
        return if targetMikuType.nil?
        Transmutation::transmute1(item, targetMikuType)
    end
end
