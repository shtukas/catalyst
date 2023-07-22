class Pure

    # Pure::containerChildrenInOrder(container)
    def self.containerChildrenInOrder(container)
        if container["mikuType"] == "TxCore" and container["uuid"] == "77a43c09-4642-45ff-b174-09898175919a" then
            # L & P to P
            items  = Tx8s::childrenInOrder(container)
            return items.sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
        end
        items  = Tx8s::childrenInOrder(container)
        waves, items  = items.partition{|item| item["mikuType"] == "Wave" }
        waves = waves.select{|item| Listing::listable(item) }
        delegates, items = items.partition{|item| item["mikuType"] == "NxDelegate" }
        longtasks, items = items.partition{|item| item["mikuType"] == "NxLongTask" }
        threads, items = items.partition{|item| item["mikuType"] == "NxThread" }
        [
            {
                "items" => waves,
                "rt" => Bank::recoveredAverageHoursPerDay2(waves)
            },
            {
                "items" => delegates,
                "rt" => Bank::recoveredAverageHoursPerDay2(delegates)
            },
            {
                "items" => items,
                "rt" => Bank::recoveredAverageHoursPerDay2(items)
            },
            {
                "items" => longtasks.sort_by{|longtask| Bank::recoveredAverageHoursPerDay(longtask["uuid"]) },
                "rt" => Bank::recoveredAverageHoursPerDay2(longtasks)
            },
            {
                "items" => threads.sort_by{|th| NxThreads::completionRatio(th) },
                "rt" => Bank::recoveredAverageHoursPerDay2(threads)
            }
        ].sort_by{|packet| packet["rt"] }.map{|packet| packet["items"] }.flatten
    end

    # Pure::childrenInOrder(item)
    def self.childrenInOrder(item)
        if item["mikuType"] == "NxThread" then
            return Pure::containerChildrenInOrder(item)
        end
        if item["mikuType"] == "TxCore" then
            return Pure::containerChildrenInOrder(item)
        end
        Tx8s::childrenInOrder(item)
    end

    # Pure::energy(item)
    def self.energy(item) # prefix + [item]
        if item["mikuType"] == "NxThread" then
            return Pure::childrenInOrder(item).take(5) + [item]
        end
        if item["mikuType"] == "TxCore" then
            return Pure::childrenInOrder(item).take(5) + [item]
        end
        [item]
    end
end
