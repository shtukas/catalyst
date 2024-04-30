
class Prefix

    # Prefix::addPrefixNxThreadTxCore(items)
    def self.addPrefixNxThreadTxCore(items)
        children = Catalyst::children(items[0])

        return items if children.empty?

        c1 = children.select{|c| Catalyst::deepRatioMinOrNull(c) }
        if c1.size > 0 then
            c2 = c1.select{|c| Catalyst::deepRatioMinOrNull(c) < 1 }
            if c2.size > 0 then
                c3 = c2.sort_by{|c| Catalyst::deepRatioMinOrNull(c) }
                return Prefix::addPrefix(c3.take(3) + items)
            end
        end

        children = children.sort_by{|i| (i["global-positioning"] || 0) }

        return Prefix::addPrefix(children.take(3) + items)
    end

    # Prefix::addPrefix(items)
    def self.addPrefix(items)
        return [] if items.empty?
        if items[0]["mikuType"] == "NxThread" then
            return Prefix::addPrefixNxThreadTxCore(items)
        end
        if items[0]["mikuType"] == "TxCore" then
            return Prefix::addPrefixNxThreadTxCore(items)
        end
        return items
    end
end
