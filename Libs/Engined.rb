

class Engined

    # Engined::listingItems()
    def self.listingItems()
        items0 = Cubes2::mikuType("NxBlock")
                    .select{|block| block["engine-0020"]["type"] == "booster" }
                    .select{|block| block["engine-0020"]["endunixtime"] <= Time.new.to_i } # expired boosters

        items1 = Cubes2::mikuType("NxBlock")
                    .select{|block| block["engine-0020"]["type"] == "booster" }
                    .select{|block| NxBlocks::dayCompletionRatio(block) < 1 }
                    .sort_by{|block| NxBlocks::dayCompletionRatio(block) }

        items2 = Cubes2::mikuType("NxTask")
                    .select{|item| item["engine-0020"] }
                    .select{|block| NxBlocks::dayCompletionRatio(block) < 1 }
                    .sort_by{|block| NxBlocks::dayCompletionRatio(block) }

        items3 = NxBlocks::blocksInRecursiveDescent()
                    .select{|block| NxBlocks::dayCompletionRatio(block) < 1 }
                    .sort_by{|block| NxBlocks::dayCompletionRatio(block) }

        items0 + items1 + items2 + items3
    end
end
