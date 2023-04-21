# encoding: UTF-8

class PriorityItems
    # PriorityItems::listingItems()
    def self.listingItems()
        (NxTasks::items()+NxCliques::items())
            .select{|item| item["priority"] }
            .sort_by{|item| BankUtils::recoveredAverageHoursPerDay(item["uuid"]) }
    end
end
