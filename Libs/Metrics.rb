
class Metrics

    # Metrics::item(item)
    def self.item(item)

        if item["mikuType"] == "NxAnniversary" then
            return 3.0
        end

        if item["mikuType"] == "PhysicalTarget" then
            return 2.5
        end

        if item["mikuType"] == "NxCore" then
            return NxCores::listingmetric(item)
        end

        if item["mikuType"] == "NxBackup" then
            return 2.0
        end

        if item["mikuType"] == "Wave" then
            return 2.3 if item["interruption"]
            return 1.5
        end

        if item["mikuType"] == "NxOndate" then
            return 1.3
        end

        raise "cannot compute metric for item: #{item}"
    end
end
