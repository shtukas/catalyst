class Pure

    # Pure::childrenInOrder(item)
    def self.childrenInOrder(item)
        if item["mikuType"] == "NxThread" then
            return NxThreads::childrenInOrderForPure(item)
        end
        Tx8s::childrenInOrder(item)
    end

    # Pure::energy(item)
    def self.energy(item) # prefix + [item]

        if item["mikuType"] == "NxThread" then
            return Pure::childrenInOrder(item).take(5) + [item]
        end
        if item["mikuType"] == "NxCore" then
            return Pure::childrenInOrder(item).take(5) + [item]
        end
        [item]
    end
end
