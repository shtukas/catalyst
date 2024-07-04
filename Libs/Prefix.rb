
class Prefix
    # Prefix::addPrefix(items)
    def self.addPrefix(items)
        return [] if items.empty?
        if items[0]["mikuType"] == "TxCore" then
            children = TxCores::childrenForPrefix(items[0])
            if children.empty? then
                return items
            end
            return Prefix::addPrefix(children.take(3) + items)
        end
        if items[0]["mikuType"] == "NxThread" then
            children = NxThreads::childrenForPrefix(items[0])
            if children.empty? then
                return items
            end
            return Prefix::addPrefix(children.take(3) + items)
        end
        return items
    end
end
