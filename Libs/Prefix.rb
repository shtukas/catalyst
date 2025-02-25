
class Prefix
    # Prefix::addPrefix(items)
    def self.addPrefix(items)
        return [] if items.empty?
        Timings::lap(JSON.pretty_generate(items[0]))
        children = PolyFunctions::childrenForPrefix(items[0])
        return items if children.empty?
        Prefix::addPrefix(children.take(3) + items)
    end
end