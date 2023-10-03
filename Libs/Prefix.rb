
class Prefix

    # Prefix::pureTopUp(item)
    # Function takes an item and returns a possible empty array of 
    # prefix items
    def self.pureTopUp(item)
        if item["mikuType"] == "TxCore" then
            return TxCores::childrenInOrder(item)
        end
        Catalyst::elementsInOrder(item)
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
