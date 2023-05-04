
class TimeCommitments

    # TimeCommitments::listingitems()
    def self.listingitems()
        (NxBoards::listingItems() + NxMonitor1s::listingItems())
            .select{|item| TxEngines::completionRatio(item["engine"]) < 1 }
            .sort_by{|item| TxEngines::completionRatio(item["engine"]) }
    end
end