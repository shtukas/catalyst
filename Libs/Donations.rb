
class Donations

    # Donations::suffix(item)
    def self.suffix(item)
        return "" if item["donation-13"].nil?
        " (d: #{item["donation-13"].join(", ")})".yellow
    end

    # Donations::interactivelySetDonation(item)
    def self.interactivelySetDonation(item)
        listings, _ = LucilleCore::selectZeroOrMore("cliques", [], Blades::mikuType("NxListing"), lambda{|listing| Listings::toString(listing) })
        donationuuids = listings.map{|nxclique| nxclique["uuid"] }
        Blades::setAttribute(item["uuid"], "donation-13", donationuuids)
    end
end
