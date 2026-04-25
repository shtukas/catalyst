
class Donations

    # Donations::suffix(item)
    def self.suffix(item)
        return "" if item["donation-14"].nil?
        description = Donations::donationId_to_description_or_null(item["donation-14"])
        return "" if description.nil?
        " (d: #{description})".yellow
    end

    # Donations::donationId_to_description_or_null(donationid)
    def self.donationId_to_description_or_null(donationid)
        target = PolyFunctions::uuid_to_item_or_null_cache_results(donationid)
        if target then
            return target["description"]
        end
        nil
    end

    # Donations::interactivelySetDonation(item) # -> item
    def self.interactivelySetDonation(item)
        target = NxEngines::interactivelySelectEnginedOrNull()
        return item if target.nil?
        Items::setAttribute(item["uuid"], "donation-14", target["uuid"])
        Items::itemOrNull(item["uuid"])
    end
end
