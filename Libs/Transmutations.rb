class Transmutations

    # Transmutations::transmute1(item)
    def self.transmute1(item)
        if item["mikuType"] == "NxOndate" then
            targetMikyType = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", ["NxTodo", "NxThread"])
            return if targetMikyType.nil?
            Transmutations::transmute2(item, targetMikyType)
        end
    end

    # Transmutations::transmute2(item, targetMikyType)
    def self.transmute2(item, targetMikyType)
        if item["mikuType"] == "NxOndate" and targetMikyType == "NxTodo" then
            thread = NxThreads::interactivelySelectOneOrNull()
            return if thread.nil?
            position = Catalyst::interactivelySelectPositionInParent(thread)
            Items::setAttribute(item["uuid"], "parentuuid-0032", thread["uuid"])
            Items::setAttribute(item["uuid"], "global-positioning", position)
            Items::setAttribute(item["uuid"], "mikuType", "NxTodo")
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikyType == "NxThread" then
            hours = NxThreads::interactivelyDecideHoursOrNull()
            Items::setAttribute(item["uuid"], "hours", hours)
            Items::setAttribute(item["uuid"], "mikuType", "NxThread")
            return
        end
        raise "(error: 12ab0d2e-7c5d-491b) could not transmute #{item} at #{targetMikyType}"
    end
end
