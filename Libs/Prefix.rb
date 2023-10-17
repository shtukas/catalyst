
class Prefix

    # Prefix::isPefixable(item)
    def self.isPefixable(item)
        if item["mikuType"] == "NxThread" then
            return TxEngines::listingCompletionRatio(item["engine-0916"]) < 1
        end
        if item["mikuType"] == "NxTask" then
            if item["engine-0916"] then
                TxEngines::listingCompletionRatio(item["engine-0916"]) < 1
            else
                Bank::recoveredAverageHoursPerDay(item["uuid"]) < 1
            end
        end
    end

    # Prefix::pureTopUp(item)
    # Takes an item and returns a possible empty array of prefix items
    def self.pureTopUp(item)
        return [] if item["mikuType"] != "NxThread"
        thread = item
        NxThreads::childrenInSortingStyleOrder(thread)
            .select{|i| Prefix::isPefixable(i) }
            .first(1)
    end

    # Prefix::prefix(items)
    def self.prefix(items)
        return [] if items.empty?
        return items if NxBalls::itemIsActive(items[0])
        topUp = Prefix::pureTopUp(items[0])
        if topUp.size > 0 then
            return Prefix::prefix(topUp + items)
        end
        return items
    end
end
