
class Engined

    # Engined::items()
    def self.items()
        Catalyst::mikuType("NxThread") + Catalyst::mikuType("NxTask").select{|item| item["engine-0916"] }
    end

    # Engined::listingItems()
    def self.listingItems()
        items = Engined::items()
            .select{|item| TxEngines::shouldListing(item) }
            .sort_by{|item| TxEngines::listingCompletionRatio(item["engine-0916"]) }
        return items if items.size > 0
        TxCores::listingItems()
    end
end
