
class Prefix
    # Prefix::addPrefix(datatrace, items)
    def self.addPrefix(datatrace, items)
        return [] if items.empty?
        if items[0]["mikuType"] == "NxThread" then
            children = Catalyst::children(datatrace, items[0])
            children = children.sort_by{|i| (i["global-positioning"] || 0) }
            return Prefix::addPrefix(datatrace, children.take(3) + items)
        end
        return items
    end
end
