
class Prefix

    # Prefix::timeControl(item)
    def self.timeControl(item)
        if item["engine-2251"] then
            TxEngine::ratio(item["engine-2251"]) < 1
        else
            Bank::recoveredAverageHoursPerDay(item["uuid"]) < 1
        end
    end

    # Prefix::pureTopUp(item)
    # Function takes an item and returns a possible empty array of 
    # prefix items
    def self.pureTopUp(item)
        if item["mikuType"] == "TxCore" then
            return TxCores::childrenInOrder(item)
                    .select{|item| Listing::listable(item) }
                    .select{|item| Prefix::timeControl(item) }
                    .first(5)
        end
        Catalyst::elementsInOrder(item)
            .select{|item| Listing::listable(item) }
            .select{|item| Prefix::timeControl(item) }
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
