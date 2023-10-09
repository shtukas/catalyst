
class Prefix

    # Prefix::responsibleRatio(item)
    def self.responsibleRatio(item)
        vs = [Bank::recoveredAverageHoursPerDay(item["uuid"])] + TxCores::childrenInOrder(item).map{|i| Prefix::responsibleRatio(i) }
        vs.max
    end

    # Prefix::pureTopUp(item)
    # Function takes an item and returns a possible empty array of 
    # prefix items
    def self.pureTopUp(item)
        if item["mikuType"] == "TxCore" then
            core = item
            return TxCores::childrenInOrder(core)
                    .select{|item| Listing::listable(item) }
                    .select{|item| Prefix::responsibleRatio(item) < 1}
                    .first(5)
        end
        Catalyst::children(item)
            .select{|item| Listing::listable(item) }
            .select{|item| Prefix::responsibleRatio(item) < 1}
            .first(5)
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
