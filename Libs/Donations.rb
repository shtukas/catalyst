
class Donations

    # Donations::suffix(item)
    def self.suffix(item)
        return "" if item["donation-13"].nil?
        " (d: #{item["donation-13"].join(", ")})".yellow
    end

    # Donations::interactivelySetDonation(item)
    def self.interactivelySetDonation(item)
        nxcliques, _ = LucilleCore::selectZeroOrMore("cliques", [], Cliques::nxCliques(), lambda{|nxclique| Cliques::toString(nxclique["uuid"]) })
        donationuuids = nxcliques.map{|nxclique| nxclique["uuid"] }
        Blades::setAttribute(item["uuid"], "donation-13", donationuuids)
    end
end
