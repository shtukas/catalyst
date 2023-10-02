
class Prefix

    # Prefix::pureTopUp(item)
    # Function takes an item and returns a possible empty array of 
    # prefix items
    def self.pureTopUp(item)
        if item["mikuType"] == "TxCore" then
            core = item
            chs = Catalyst::mikuType("NxTask")
                    .select{|i2| i2["coreX-2300"] == core["uuid"] }
                    .select{|i2| i2["engine-2251"].nil? }
                    .sort_by{|collection| Bank::recoveredAverageHoursPerDay(collection["uuid"]) }
                    .first(3)
            return Prefix::prefix(chs)
        end
        if item["mikuType"] == "NxClique" then
            return NxCliques::elementsInOrder(item).first(3)
        end
        []
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
