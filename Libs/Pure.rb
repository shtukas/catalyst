
class Pure

    # Pure::pure(items)
    def self.pure(items)
        return [] if items.empty?
        i1 = items[0]
        i2 = items.drop(1)
        children = Tx8s::childrenInOrder(i1).first(5)
        if children.empty? then
            return items
        end
        Pure::pure(children + items)
    end
end
