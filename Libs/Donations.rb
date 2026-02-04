
class Donations

    # Donations::suffix(item)
    def self.suffix(item)
        return "" if item["donation-13"].nil?
        str = item["donation-13"].map{|uuid| Blades::itemOrNull(uuid) }.compact.map{|i| i["description"] }.join(", ")
        " (d: #{str})".yellow
    end

    # Donations::interactivelySetDonation(item) # -> item
    def self.interactivelySetDonation(item)
        listings = CommonUtils::selectZeroOrMore(Blades::mikuType("NxListing"), lambda{|listing| PolyFunctions::toString(listing) })
        return item if listings.empty?
        donationuuids = listings.map{|nxclique| nxclique["uuid"] }
        Blades::setAttribute(item["uuid"], "donation-13", donationuuids)
        Blades::itemOrNull(item["uuid"])
    end
end
