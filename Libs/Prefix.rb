
class Prefix

    # Prefix::prefix(items)
    def self.prefix(items)
        return [] if items.empty?

        stratification = NxStrats::stratification([items[0]])
        if stratification.size > 1 then
            return stratification.take(stratification.size-1) + items
        end

        if items[0]["mikuType"] == "TxCore" then
            children = TxCores::childrenInOrder(items[0])
                            .select{|i| i["engine-0916"].nil? or TxEngines::dailyRelativeCompletionRatio(i["engine-0916"]) < 1 }
                            .select{|i| Listing::listable(i) }
                            .first(1)
            if children.size > 0 then
                return Prefix::prefix(children + items)
            end
        end

        return items
    end
end
