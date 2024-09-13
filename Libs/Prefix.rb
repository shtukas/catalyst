
class Prefix
    # Prefix::addPrefix(items)
    def self.addPrefix(items)
        return [] if items.empty?
        if items[0]["mikuType"] == "NxTask" then
            children = TxCores::childrenForPrefix(items[0])
                        .select{|item| Listing::listable(item) }
            if children.empty? then
                return items
            end
            return Prefix::addPrefix(children.take(3) + items)
        end
        if items[0]["mikuType"] == "NxThread" then
            children = NxThreads::childrenForPrefix(items[0])
                        .select{|item| Listing::listable(item) }
            if children.empty? then
                return items
            end
            return Prefix::addPrefix(children.take(3) + items)
        end

        if items[0]["uuid"] == "85e2e9fe-ef3d-4f75-9330-2804c4bcd52b" then
            # infinity
            children = TxCores::childrenForInfinityPrefix()
                        .select{|item| Listing::listable(item) }
            if children.empty? then
                return items
            end
            return Prefix::addPrefix(children.take(3) + items)
        end

        if items[0]["mikuType"] == "TxCore" then
            children = TxCores::childrenForPrefix(items[0])
                        .select{|item| Listing::listable(item) }
            if children.empty? then
                return items
            end
            return Prefix::addPrefix(children.take(3) + items)
        end
        return items
    end
end
