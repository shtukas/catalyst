
class Transmutation

    # Transmutation::transmute1(item, targetMikuType)
    def self.transmute1(item, targetMikuType)
        return if targetMikuType.nil?
        puts "Transmuting '#{PolyFunctions::toString(item)}' from #{item["mikuType"]} to #{targetMikuType}"
        
        if item["mikuType"] == "NxDated" and targetMikuType == "NxTask" then
            NxTasks::performGeneralItemPositioning(item)
            Items::setAttribute(item["uuid"], "mikuType", "NxTask")
            return
        end
        puts "I do not know how to transmute mikuType #{item["mikuType"]} to #{targetMikuType}. Aborting."
        exit
    end

    # Transmutation::transmute2(item)
    def self.transmute2(item)
        if item["mikuType"] == "NxDated" then
            targetMikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("MikuType", ["NxTask"])
        end
        Transmutation::transmute1(item, targetMikuType)
    end
end
