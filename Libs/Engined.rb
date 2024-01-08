

class Engined

    # Engined::muiItems()
    def self.muiItems()
        tasks = Cubes2::mikuType("NxTask").select{|item| item["engine-0020"] }
        daylies = Cubes2::mikuType("NxListing")
                    .select{|listing| listing["engine-0020"]["type"] == "daily-hours" }
        (tasks + daylies + NxListings::topBlocks())
                .select{|item| NxListings::dayCompletionRatio(item) < 1 }
                .sort_by{|item| NxListings::dayCompletionRatio(item) }
    end
end
