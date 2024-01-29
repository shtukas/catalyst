
class Prefix

    # Prefix::prefix(items)
    def self.prefix(items)
        return [] if items.empty?

        stratification = NxStrats::stratification([items[0]])
        if stratification.size > 1 then
            return stratification.take(stratification.size-1) + items
        end

        if items[0]["mikuType"] == "NxTodo" then
            children = NxTodos::children(items[0])
                        .select{|i| MainUserInterface::listable(i) }
                        .first(3)
            if children.size > 0 then
                return Prefix::prefix(children + items)
            end
        end

        if items[0]["mikuType"] == "NxOrbital" then
            children = NxOrbitals::children(items[0])
                        .select{|i| MainUserInterface::listable(i) }
                        .first(3)
            if children.size > 0 then
                return Prefix::prefix(children + items)
            end
        end

        return items
    end
end