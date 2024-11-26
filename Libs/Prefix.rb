
class Prefix
    # Prefix::addPrefix(items)
    def self.addPrefix(items)
        return [] if items.empty?
        if (top = NxStrats::topOrNull(items[0]["uuid"])) then
            return Prefix::addPrefix([top] + items)
        end
        if items[0]["mikuType"] == "NxTimeCapsule" then
            if items[0]["targetuuid"] then
                target = Items::itemOrNull(items[0]["targetuuid"])
                if target then
                    return Prefix::addPrefix([target] + items)
                end
            end
            return items
        end
        if items[0]["mikuType"] == "NxCore" then
            children = PolyFunctions::children(items[0])
                        .select{|item| Listing::listable(item) }
            if children.empty? then
                return items
            end
            return Prefix::addPrefix(children.take(3) + items)
        end
        return items
    end
end