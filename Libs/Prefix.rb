
class Prefix

    # Prefix::pureTopUp(item)
    def self.pureTopUp(item)
        Tx8s::childrenInOrder(item).first(5)
    end

    # Prefix::prefix(items)
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
