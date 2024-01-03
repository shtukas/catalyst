

class Engined

    # Engined::listingItems()
    def self.listingItems()
        tasks = Cubes2::mikuType("NxTask").select{|item| item["engine-0020"] }
        (tasks + NxBlocks::topBlocks())
            .select{|block| NxBlocks::dayCompletionRatio(block) < 1 }
            .sort_by{|block| NxBlocks::dayCompletionRatio(block) }
    end
end
