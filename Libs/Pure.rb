class Pure

    # Pure::energy(item)
    def self.energy(item) # prefix + [item]
        if item["mikuType"] == "NxDaily" then
            return Pure::energy(item["item"]) + [item]
        end
        if item["mikuType"] == "NxThread" then
            return Tx8s::childrenInOrder(item).take(5) + [item]
        end
        [item]
    end
end
