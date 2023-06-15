
class Pure

    # Pure::pure()
    def self.pure()
        listing = DarkEnergy::mikuType("NxCore")
                    .select{|core| NxCores::listingCompletionRatio(core) < 1 }
                    .sort_by{|core| NxCores::listingCompletionRatio(core) }
        return [] if listing.empty?
        listing = Parenting::childrenInRelevantOrder(listing.first).first(6) + listing
        listing = Parenting::childrenInRelevantOrder(listing.first).first(6) + listing
        listing
    end
end
