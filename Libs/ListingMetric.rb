
class ListingMetric

    # ListingMetric::metricOrNull(item, usePrecomputation = false)
    def self.metricOrNull(item, usePrecomputation = false)

        if usePrecomputation then
            return Precomputations::listingMetricOrNull(item)
        end

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
            ratio = NxTasks::ratio(item)
            return nil if ratio > 1
            return 0.5 + 0.5*ratio
        end

        if item["mikuType"] == "NxMonitor" then
            ratio = NxMonitors::ratio(item)
            return nil if ratio > 1
            return 0.5 + 0.5*ratio
        end

        if item["mikuType"] == "NxCore" then
            ratio = NxCores::ratio(item)
            return nil if ratio > 1
            return 0.5 + 0.5*ratio
        end

        raise "I do not know how to metric #{item}"
    end
end
