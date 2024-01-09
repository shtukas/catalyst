
class Engined

    # Engined::muiItems()
    def self.muiItems()
        tasks = Cubes2::mikuType("NxTask").select{|item| item["engine-0020"] }
                .sort_by{|item| NxListings::dayCompletionRatio(item) }

        listings1 = Cubes2::mikuType("NxListing")
                    .select{|listing| listing["engine-0020"]["type"] == "daily-hours" }
                    .sort_by{|item| NxListings::dayCompletionRatio(item) }

        listings2 = Cubes2::mikuType("NxListing")
                    .select{|listing| listing["engine-0020"]["type"] != "daily-hours" }
                    .sort_by{|item| NxListings::dayCompletionRatio(item) }

        (tasks + listings1 + listings2)
            .select{|item| NxListings::dayCompletionRatio(item) < 1 }
    end
end
