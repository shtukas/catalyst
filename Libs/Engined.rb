
class Engined

    # Engined::muiItems()
    def self.muiItems()
        tasks = Cubes2::mikuType("NxTask").select{|item| item["engine-0020"] }
            .sort_by{|item| NxListings::dayCompletionRatio(item) }

        listings = NxListings::topListings()

        (tasks + listings)
            .sort_by{|item| NxListings::dayCompletionRatio(item) }
            .partition{|item| NxListings::dayCompletionRatio(item) < 1 }
    end
end
