
class Prefix

    # Prefix::pureTopUp(item)
    # Takes an item and returns a possible empty array of prefix items
    def self.pureTopUp(item)
        return [] if item["mikuType"] != "NxThread"
        thread = item
        NxThreads::childrenInSortingStyleOrder(thread).first(1)
    end

    # Prefix::prefix(items)
    def self.prefix(items)
        return [] if items.empty?
        topUp = Prefix::pureTopUp(items[0])
        if topUp.size > 0 then
            return Prefix::prefix(topUp + items)
        end
        return items
    end
end
