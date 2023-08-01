class Pure

    # Pure::childrenInOrder3(container)
    def self.childrenInOrder3(container)
        if container["mikuType"] == "TxCore" and container["uuid"] == "77a43c09-4642-45ff-b174-09898175919a" then
            # L & P to P
            items  = Tx8s::childrenInOrder(container)
            return items.sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
        end
        items  = Tx8s::childrenInOrder(container)
        waves, items  = items.partition{|item| item["mikuType"] == "Wave" }
        waves = waves.select{|item| Listing::listable(item) }
        delegates, items = items.partition{|item| item["mikuType"] == "NxDelegate" }
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
                "items" => threads.sort_by{|th| NxThreads::completionRatio(th) },
                "rt" => Bank::recoveredAverageHoursPerDay2(threads)
            }
        ].sort_by{|packet| packet["rt"] }.map{|packet| packet["items"] }.flatten
    end

    # Pure::childrenInOrder2(item)
    def self.childrenInOrder2(item)
        if item["mikuType"] == "NxThread" then
            return Pure::childrenInOrder3(item)
        end
        if item["mikuType"] == "TxCore" then
            return Pure::childrenInOrder3(item)
        end
        Tx8s::childrenInOrder(item)
    end

    # Pure::energy(item)
    def self.energy(item) # prefix + [item]
        children = Pure::childrenInOrder2(item)
        if children.empty? then
            return [item]
        else
            c1 = children.first
            c2 = children.drop(1).take(5)
            return Pure::energy(c1) + c2 + [item]

        end
    end
end
