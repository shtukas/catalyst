class Transmutations

    # Transmutations::transmute1(item)
    def self.transmute1(item)
        if item["mikuType"] == "NxOndate" then
            targetMikyType = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", ["NxTask", "NxCollection", "Wave"])
            return if targetMikyType.nil?
            Transmutations::transmute2(item, targetMikyType)
        end
        if item["mikuType"] == "NxCollection" then
            targetMikyType = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", ["TxCore"])
            return if targetMikyType.nil?
            Transmutations::transmute2(item, targetMikyType)
        end
    end

    # Transmutations::transmute2(item, targetMikyType)
    def self.transmute2(item, targetMikyType)
        if item["mikuType"] == "NxOndate" and targetMikyType == "NxTask" then
            thread = NxCollections::interactivelySelectOneOrNull()
            return if thread.nil?
            position = Catalyst::interactivelySelectPositionInParent(thread)
            Items::setAttribute(item["uuid"], "parentuuid-0032", thread["uuid"])
            Items::setAttribute(item["uuid"], "global-positioning", position)
            Items::setAttribute(item["uuid"], "mikuType", "NxTask")
            return
        end
        if item["mikuType"] == "NxOndate" and targetMikyType == "NxCollection" then
            hours = NxCollections::interactivelyDecideHoursOrNull()
            Items::setAttribute(item["uuid"], "hours-1905", hours)
            Items::setAttribute(item["uuid"], "mikuType", "NxCollection")
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
        if item["mikuType"] == "NxCollection" and targetMikyType == "TxCore" then
            hours = nil
            loop {
                hours = NxCollections::interactivelyDecideHoursOrNull()
                break if hours
            }
            Items::setAttribute(item["uuid"], "hours-1905", hours)
            Items::setAttribute(item["uuid"], "mikuType", "TxCore")
            return
        end
        raise "(error: 12ab0d2e-7c5d-491b) could not transmute #{item} at #{targetMikyType}"
    end
end
