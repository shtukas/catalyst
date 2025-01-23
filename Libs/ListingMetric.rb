
class ListingMetric
    
    # ListingMetric::metric(item)
    def self.metric(item)

        if item["mikuType"] == "NxAnniversary" then
            return 10
        end

        if item["mikuType"] == "Wave" and item["interruption"] then
            return 9
        end

        if item["mikuType"] == "NxDated" then
            return 8
        end

        if item["mikuType"] == "NxFloat" then
            return 7
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
            return 4
        end

        if item["mikuType"] == "NxCore" then
            ratio = NxCores::ratio(item)
            return nil if ratio >= 1
            return 3 + 0.9 - 0.001*ratio
        end

        if item["mikuType"] == "NxMonitor" then
            ratio = NxMonitors::ratio(item)
            return nil if ratio >= 1
            return 2 + 0.9 - 0.001*ratio
        end

        if item["mikuType"] == "Wave" and !item["interruption"] then
            return 0
        end

        raise "I do not know how to metric #{item}"
    end
end
