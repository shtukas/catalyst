
class Prefix

    # Prefix::polymorphRatio(item)
    def self.polymorphRatio(item)
        if item["engine-2251"] then
            TxEngine::ratio(item["engine-2251"]) < 1
        else
            Bank::recoveredAverageHoursPerDay(item["uuid"]) < 1
        end
    end

    # Prefix::responsibleRatio(item)
    def self.responsibleRatio(item)
        vs = [Prefix::polymorphRatio(item)] + TxCores::childrenInOrder(item).map{|i| Prefix::responsibleRatio(item) }
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
        Catalyst::elementsInOrder(item)
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
