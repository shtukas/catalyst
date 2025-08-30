
class Prefix
    # Prefix::prefix(item) -> Array[Item]
    def self.prefix(item)
        children = Parenting::childrenInOrder(item["uuid"]).reduce([]){|selected, item|
            if selected.size >= 3 then
                selected
            else
                if DoNotShowUntil::isVisible(item["uuid"]) then
                    selected + [item]
                else
                    selected
                end
            end
        }
        return [] if children.empty?
        Prefix::prefix(children[0]) + children
    end
end
