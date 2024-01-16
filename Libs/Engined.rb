
class Engined

    # Engined::muiItems()
    def self.muiItems()
        Cubes2::items()
            .select{|item| item["engine-0020"] }
            .sort_by{|item| TxCores::dayCompletionRatio(item["engine-0020"]) }
            .partition{|item| TxCores::dayCompletionRatio(item["engine-0020"]) < 1 }
    end
end
