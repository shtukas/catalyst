
class Transmutation

    # Transmutation::transmute1(item, targetMikuType)
    def self.transmute1(item, targetMikuType)
        return if targetMikuType.nil?
        puts "Transmuting '#{PolyFunctions::toString(item)}' from #{item["mikuType"]} to #{targetMikuType}"
        
        if item["mikuType"] == "NxDated" and targetMikuType == "NxTask" then
            NxTasks::performGeneralItemPositioning(item)
            Items::setAttribute(item["uuid"], "global-positioning-4233", rand)
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
            Items::setAttribute(item["uuid"], "engine-1706", nil)
            Items::setAttribute(item["uuid"], "engine-1706", nil)
            Items::setAttribute(item["uuid"], "mikuType", "NxDated")
            return
        end
        puts "I do not know how to transmute mikuType #{item["mikuType"]} to #{targetMikuType}. Aborting."
        exit
    end

    # Transmutation::transmute2(item)
    def self.transmute2(item)
        if item["mikuType"] == "NxDated" then
            targetMikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("MikuType", ["NxTask", "NxFloat"])
        end
        Transmutation::transmute1(item, targetMikuType)
    end
end
