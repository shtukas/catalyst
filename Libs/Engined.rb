

class Engined

    # Engined::listingItems()
    def self.listingItems()
        tasks = Cubes2::mikuType("NxTask").select{|item| item["engine-0020"] }
        items = (tasks + NxBlocks::topBlocks())
        p1, p2 = items.partition{|item| item["engine-0020"]["type"] == "daily-hours" }
        [p1, p2].map{|px|
            px
                .select{|item| NxBlocks::dayCompletionRatio(item) < 1 }
                .sort_by{|item| NxBlocks::dayCompletionRatio(item) }
        }
        .flatten
    end
end
