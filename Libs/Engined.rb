
class Engined

    # Engined::muiItems()
    def self.muiItems()
        tasks = Cubes2::mikuType("NxTask").select{|item| item["engine-0020"] }
                .sort_by{|item| NxListings::dayCompletionRatio(item) }

        listings = NxListings::topListings()
        listings = listings.select{|listing| NxListings::shouldIncludeInMuiItems(listing) }

        listings1 = listings
                    .select{|listing| listing["engine-0020"]["type"] == "daily-hours" }
                    .sort_by{|item| NxListings::dayCompletionRatio(item) }

        listings2 = listings
                    .select{|listing| listing["engine-0020"]["type"] != "daily-hours" }
                    .sort_by{|item| NxListings::dayCompletionRatio(item) }

        (tasks + listings1 + listings2).partition{|item| NxListings::dayCompletionRatio(item) < 1 }
    end
end
