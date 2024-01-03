

class Engined

    # Engined::listingItems()
    def self.listingItems()
        tasks = Cubes2::mikuType("NxTask").select{|item| item["engine-0020"] }
        (tasks + NxBlocks::topBlocks())
            .select{|item| NxBlocks::dayCompletionRatio(item) < 1 }
            .sort_by{|item| NxBlocks::dayCompletionRatio(item) }
    end
end
