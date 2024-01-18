
class Engined

    # Engined::muiItems2()
    def self.muiItems2()
        Cubes2::items()
            .select{|item| item["engine-0020"] }
            .select{|item| TxCores::listingCompletionRatio(item["engine-0020"]) >= 1 }
            .sort_by{|item| TxCores::listingCompletionRatio(item["engine-0020"]) }
    end
end
