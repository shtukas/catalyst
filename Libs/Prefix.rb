
class Prefix
    # Prefix::addPrefix(items)
    def self.addPrefix(items)
        return [] if items.empty?
        children = PolyFunctions::children(items[0])
        return items if children.empty?
        Prefix::addPrefix(children.take(3) + items)
    end
end