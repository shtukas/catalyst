
class Pure

    # Pure::pure()
    def self.pure()
        listing = DarkEnergy::mikuType("NxCore")
                    .select{|core| NxCores::listingCompletionRatio(core) < 1 }
                    .select{|core| DoNotShowUntil::isVisible(core) }
                    .sort_by{|core| NxCores::listingCompletionRatio(core) }
        return [] if listing.empty?
        head = Parenting::childrenInRelevantOrder(listing.first)
                    .select{|item| DoNotShowUntil::isVisible(item) }
                    .first(6)
        listing = head + listing
        head = Parenting::childrenInRelevantOrder(listing.first)
                    .select{|item| DoNotShowUntil::isVisible(item) }
                    .first(6)
        listing = head + listing
        listing
    end
end
