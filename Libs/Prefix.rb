
class Prefix

    # Prefix::pureTopUp(item)
    # Function takes an item and returns a possible empty array of 
    # prefix items
    def self.pureTopUp(item)
        if item["mikuType"] == "TxCore" then
            core = item
            chs = (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxCollection"))
                    .select{|i2| i2["coreX-2300"] == core["uuid"] }
                    .select{|i2| i2["engine-2251"].nil? }
                    .sort_by{|collection| Bank::recoveredAverageHoursPerDay(collection["uuid"]) }
                    .first(3)
            return Prefix::prefix(chs)
        end
        if item["mikuType"] == "NxCollection" then
            collection = item
            return Prefix::prefix(NxCollections::childrenInOrder(collection).first(3))
        end
        []
    end

    # Prefix::prefix(items)
    # Function takes an array of items and prefixes it with any relevant stratification or top up
    def self.prefix(items)
        return [] if items.empty?
        stratification = Stratification::getItemStratification(items[0])
        if stratification.size > 0 then
            return stratification.reverse + items
        end
        topUp = Prefix::pureTopUp(items[0])
        if topUp.size > 0 then
            return Prefix::prefix(topUp + items)
        end
        return items
    end
end
