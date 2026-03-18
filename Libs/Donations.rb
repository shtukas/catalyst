
class Donations

    # Donations::suffix(item)
    def self.suffix(item)
        return "" if item["donation-14"].nil?
        target = PolyFunctions::uuid_to_item_or_null_cache_results(item["donation-14"])
        return "" if target.nil?
        " (d: #{target["description"]})".yellow
    end

    # Donations::interactivelySetDonation(item) # -> item
    def self.interactivelySetDonation(item)
        core = TimeCores::interactively_select_core_or_null()
        return item if core.nil?
        Blades::setAttribute(item["uuid"], "donation-14", core["uuid"])
        Blades::itemOrNull(item["uuid"])
    end
end
