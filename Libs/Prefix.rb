
class Prefix

    # Prefix::prefix(items)
    def self.prefix(items)
        return [] if items.empty?

        stratification = NxStrats::stratification([items[0]])
        if stratification.size > 1 then
            return stratification.take(stratification.size-1) + items
        end

        if items[0]["mikuType"] == "NxBlock" then
            children = NxBlocks::elementsForPrefix(items[0])
                        .select{|i| Listing::listable(i) }
                        .first(6)
            if children.size > 0 then
                return Prefix::prefix(children + items)
            end
        end

        return items
    end
end