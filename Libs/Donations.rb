
class Donations

    # Donations::suffix(item)
    def self.suffix(item)
        return "" if item["donation-14"].nil?
        target = Blades::itemOrNull(item["donation-14"])
        return "" if target.nil?
        " (d: #{target["description"]})".yellow
    end

    # Donations::interactivelySetDonation(item) # -> item
    def self.interactivelySetDonation(item)
        listing = CommonUtils::selectEntityFromListOfEntitiesOrNull("item", Blades::mikuType("NxListing"), lambda{|listing| PolyFunctions::toString(listing) })
        return item if listings.nil?
        Blades::setAttribute(item["uuid"], "donation-14", listing["uuid"])
        Blades::itemOrNull(item["uuid"])
    end
end
