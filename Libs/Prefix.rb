
class Prefix
    # Prefix::addPrefix(items, usePrecomputation = false)
    def self.addPrefix(items, usePrecomputation = false)
        if usePrecomputation then
            return Precomputations::addPrefix(items)
        end
        return [] if items.empty?
        children = PolyFunctions::childrenForPrefix(items[0])
        return items if children.empty?
        Prefix::addPrefix(children.take(3) + items, usePrecomputation)
    end
end