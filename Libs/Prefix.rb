
class Prefix

    # Prefix::addPrefix(items)
    def self.addPrefix(items)
        return [] if items.empty?

        if items[0]["mikuType"] == "NxThread" then
            children = Catalyst::children(items[0])
            return items if children.empty?
            return Prefix::addPrefix(children.take(3) + items)
        end

        if items[0]["mikuType"] == "TxCore" then
            children = Catalyst::children(items[0])
            return items if children.empty?
            return Prefix::addPrefix(children.take(3) + items)
        end

        return items
    end
end
