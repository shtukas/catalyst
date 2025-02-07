
class ListingMetric

    # ListingMetric::metric(item)
    def self.metric(item)
        if item["mikuType"] == "NxAnniversary" then
            return NxFlightData::itemToListingMetric(item)
        end

        if item["mikuType"] == "Wave" and item["interruption"] then
            return NxFlightData::itemToListingMetric(item)
        end

        if item["mikuType"] == "NxDated" then
            return NxFlightData::itemToListingMetric(item)
        end

        if item["mikuType"] == "NxFloat" then
            return NxFlightData::itemToListingMetric(item)
        end

        if item["mikuType"] == "Wave" and !item["interruption"] then
            return NxFlightData::itemToListingMetric(item)
        end

        if item["mikuType"] == "NxBackup" then
            return NxFlightData::itemToListingMetric(item)
        end

        if item["mikuType"] == "NxTask" and NxTasks::isActive(item) then
            return 0.2 + 0.8*NxTasks::activeItemRatio(item)
        end

        if item["mikuType"] == "NxMonitor" then
            return 0.2 + 0.8*NxMonitors::ratio(item)
        end

        if item["mikuType"] == "NxCore" then
            return 0.2 + 0.8*NxCores::ratio(item)
        end

        if item["mikuType"] == "NxStackPriority" then
            return item["position"] || 0
        end

        raise "I do not know how to metric #{item}"
    end
end
