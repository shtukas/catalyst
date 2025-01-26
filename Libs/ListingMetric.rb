
class ListingMetric

    # ListingMetric::getEpsilon(item)
    def self.getEpsilon(item)
        return item["epsilon-657933b6"] if item["epsilon-657933b6"]
        epsilon = 0.001*rand
        Items::setAttribute(item["uuid"], "epsilon-657933b6", epsilon)
        epsilon
    end

    # ListingMetric::metric(item)
    def self.metric(item)

        if item["mikuType"] == "NxAnniversary" then
            return 11 + ListingMetric::getEpsilon(item)
        end

        if item["mikuType"] == "Wave" and item["interruption"] then
            return 10 + ListingMetric::getEpsilon(item)
        end

        if item["mikuType"] == "NxDated" then
            return 9 + ListingMetric::getEpsilon(item)
        end

        if item["mikuType"] == "NxFloat" then
            return 8 + ListingMetric::getEpsilon(item)
        end

        if item["mikuType"] == "Wave" and !item["interruption"] then
            return 7 + ListingMetric::getEpsilon(item)
        end

        if item["mikuType"] == "NxTask" and NxTasks::isActive(item) and item["hours-2037"] then
            ratio = NxTasks::ratio(item)
            return nil if ratio >= 1
            return 6 + 0.9 - 0.001*ratio
        end

        if item["mikuType"] == "NxTask" and NxTasks::isActive(item) and item["hours-2037"].nil? then
            ratio = NxTasks::ratio(item)
            return nil if ratio >= 1
            return 5 + 0.9 - 0.001*ratio
        end

        if item["mikuType"] == "NxBackup" then
            return 4 + ListingMetric::getEpsilon(item)
        end

        if item["mikuType"] == "NxMonitor" then
            ratio = NxMonitors::ratio(item)
            return nil if ratio >= 1
            return 3 + 0.9 - 0.001*ratio
        end

        if item["mikuType"] == "NxCore" then
            ratio = NxCores::ratio(item)
            return nil if ratio >= 1
            return 2 + 0.9 - 0.001*ratio
        end

        raise "I do not know how to metric #{item}"
    end
end
