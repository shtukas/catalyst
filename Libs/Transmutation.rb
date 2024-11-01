
class Transmutation

    # Transmutation::transmute1(item, targetMikuType)
    def self.transmute1(item, targetMikuType)
        return if targetMikuType.nil?
        puts "Transmuting '#{PolyFunctions::toString(item)}' from #{item["mikuType"]} to #{targetMikuType}"
        
        if item["mikuType"] == "NxDated" and targetMikuType == "NxTask" then

            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["infinity, 10 to 20 task", "hierarchical"])
            return if option.nil?

            if option == "infinity, 10 to 20 task" then
                position = NxTasks::between10And20InfinityPosition()
                Items::setAttribute(item["uuid"], "global-positioning", position)
            end

            if option == "hierarchical" then
                parent = Catalyst::interactivelySelectParentInHierarchyOrNull(nil)
                return if parent.nil?
                Items::setAttribute(item["uuid"], "parentuuid-0014", parent["uuid"])
            end

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
