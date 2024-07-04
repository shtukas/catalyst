class Transmutations

    # Transmutations::transmute1(item)
    def self.transmute1(item)
        if item["mikuType"] == "NxOndate" then
            targetMikyType = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", ["NxTask", "NxThread", "Wave"])
            return if targetMikyType.nil?
            Transmutations::transmute2(item, targetMikyType)
        end
        if item["mikuType"] == "NxThread" then
            targetMikyType = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", ["TxCore"])
            return if targetMikyType.nil?
            Transmutations::transmute2(item, targetMikyType)
        end
    end

    # Transmutations::transmute2(item, targetMikyType)
    def self.transmute2(item, targetMikyType)
        if item["mikuType"] == "NxOndate" and targetMikyType == "NxTask" then
            thread = NxThreads::interactivelySelectOneOrNull()
            return if thread.nil?
            position = Catalyst::interactivelySelectPositionInParent(thread)
            Items::setAttribute(item["uuid"], "parentuuid-0032", thread["uuid"])
            Items::setAttribute(item["uuid"], "global-positioning", position)
            Items::setAttribute(item["uuid"], "mikuType", "NxTask")
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikyType == "NxThread" then
            hours = NxThreads::interactivelyDecideHoursOrNull()
            Items::setAttribute(item["uuid"], "hours", hours)
            Items::setAttribute(item["uuid"], "mikuType", "NxThread")
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikyType == "Wave" then
            nx46 = Waves::makeNx46InteractivelyOrNull()
            return if nx46.nil?
            Items::setAttribute(item["uuid"], "nx46", nx46)
            Items::setAttribute(item["uuid"], "lastDoneDateTime", "#{Time.new.strftime("%Y")}-01-01T00:00:00Z")
            Items::setAttribute(item["uuid"], "mikuType", "Wave")
            return
        end
        if item["mikuType"] == "NxThread" and targetMikyType == "TxCore" then
            hours = nil
            loop {
                hours = NxThreads::interactivelyDecideHoursOrNull()
                break if hours
            }
            Items::setAttribute(item["uuid"], "hours", hours)
            Items::setAttribute(item["uuid"], "mikuType", "TxCore")
            return
        end
        raise "(error: 12ab0d2e-7c5d-491b) could not transmute #{item} at #{targetMikyType}"
    end
end
