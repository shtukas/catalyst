
class Prefix

    # Prefix::isBankPrefixable(item)
    def self.isBankPrefixable(item)
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

    # Prefix::threadTreeStructureTopUp(item)
    # Takes an item and returns a possible empty array of prefix items
    def self.threadTreeStructureTopUp(item)
        return [] if item["mikuType"] != "NxThread"
        thread = item
        NxThreads::childrenInOrder(thread)
            .select{|i| Prefix::isBankPrefixable(i) }
            .select{|i| Listing::listable(i) }
            .first(1)
    end

    # Prefix::prefix(items)
    def self.prefix(items)
        return [] if items.empty?

        stratification = NxStrats::stratification([items[0]])
        if stratification.size > 1 then
            return stratification.take(stratification.size-1) + items
        end

        topUp2 = Prefix::threadTreeStructureTopUp(items[0])
        if topUp2.size > 0 then
            return Prefix::prefix(topUp2 + items)
        end
        return items
    end
end
