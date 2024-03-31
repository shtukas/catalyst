
class Prefix

    # Prefix::mark(items)
    def self.mark(items)
        items.map{|item|
            item["x:prefix:0859"] = true
            item
        }
    end

    # Prefix::addPrefix(items)
    def self.addPrefix(items)
        return [] if items.empty?

        if items[0]["mikuType"] == "NxThread" then
            children = NxThreads::children(items[0])
            return items if children.empty?
            return Prefix::addPrefix(Prefix::mark(children.take(3)) + items)
        end

        return items
    end
end
