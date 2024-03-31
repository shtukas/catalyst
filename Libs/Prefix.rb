
class Prefix

    # Prefix::mark(items, i)
    def self.mark(items, i)
        items.map{|item|
            item["x:prefix:0859"] = i
            item
        }
    end

    # Prefix::addPrefix(items, i = 0)
    def self.addPrefix(items, i = 0)
        return [] if items.empty?

        if items[0]["mikuType"] == "NxThread" then
            children = Catalyst::children(items[0])
            return items if children.empty?
            return Prefix::addPrefix(Prefix::mark(children.take(3), i+1) + items, i+1)
        end

        if items[0]["mikuType"] == "NxTodo" then
            children = Catalyst::children(items[0])
            return items if children.empty?
            return Prefix::addPrefix(Prefix::mark(children.take(3), i+1) + items, i+1)
        end

        return items
    end
end
