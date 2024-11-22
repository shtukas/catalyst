
class Prefix
    # Prefix::addPrefix(items)
    def self.addPrefix(items)
        return [] if items.empty?
        if (top = NxStrats::topOrNull(items[0]["uuid"])) then
            return Prefix::addPrefix([top] + items)
        end
        if items[0]["mikuType"] == "NxCore" then
            children = Catalyst::children(items[0])
                        .select{|item| Listing::listable(item) }
            if children.empty? then
                return items
            end
            return Prefix::addPrefix(children.take(3) + items)
        end
        return items
    end
end