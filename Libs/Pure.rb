
class Pure

    # Pure::childrenInitInRelevantOrder(item)
    def self.childrenInitInRelevantOrder(item)
        return (NxStacks::stack(item) + [item]) if item["mikuType"] == "NxTask"

        if item["mikuType"] == "NxCore" then
            return NxCores::children(item)
                .sort_by{|item| item["unixtime"] }
                .select{|item| DoNotShowUntil::isVisible(item) }
                .select{|item| Bank::getValueAtDate(item["uuid"], CommonUtils::today()) < 3600*2 }
                .first(6)
        end

        raise "don't know how to children item #{item}"
    end

    # Pure::pure()
    def self.pure()
        listing = DarkEnergy::mikuType("NxCore")
                    .select{|core| DoNotShowUntil::isVisible(core) }
                    .select{|core| NxCores::listingCompletionRatio(core) < 1 }
                    .sort_by{|core| NxCores::listingCompletionRatio(core) }
        return [] if listing.empty?
        head = Pure::childrenInitInRelevantOrder(listing.first)
        listing = head + listing
        head = Pure::childrenInitInRelevantOrder(listing.first)
        listing = head + listing
        listing
    end
end
