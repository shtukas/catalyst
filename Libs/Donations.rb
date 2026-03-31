
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
        "description 09"
        target = PolyFunctions::uuid_to_item_or_null_cache_results(donationid)
        if target then
            return target["description"]
        end

        TimeCores::get_timecore_description_or_null_cache_results(donationid)
    end

    # Donations::interactivelySetDonation(item) # -> item
    def self.interactivelySetDonation(item)
        core = TimeCores::interactively_select_core_or_null()
        return item if core.nil?
        Blades::setAttribute(item["uuid"], "donation-14", core["uuid"])
        Blades::itemOrNull(item["uuid"])
    end
end
