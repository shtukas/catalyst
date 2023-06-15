
class Pure

    # Pure::pure2(item)
    def self.pure2(item)
        children = Parenting::children(item)
        if item["mikuType"] == "NxTask" then
            return item
        end
        if item["mikuType"] == "NxCore" then
            collection = Parenting::childrenInPositionOrder(item)
                        .first(6)
                        .select{|child| ["NxTask", "TxPool", "TxStack"].include?(child["mikuType"]) }
                        .map{|child| Pure::pure2(child) }
                        .flatten
            return collection
        end
        if item["mikuType"] == "TxStack" then
            collection = Parenting::childrenInPositionOrder(item)
                        .first(6)
                        .map{|child| Pure::pure2(child) }
                        .flatten
            return collection + [item]
        end
        if item["mikuType"] == "TxPool" then
            collection = Parenting::childrenInRecoveryTimeOrder(item)
                        .first(6)
                        .map{|child| Pure::pure2(child) }
                        .flatten
            return collection + [item]
        end
        raise "(error: 56e8ed13-6f18-4bc1-a7be-ec9b218f43db) #{item}"
    end

    # Pure::pure1()
    def self.pure1()
        DarkEnergy::mikuType("NxCore")
            .select{|core| NxCores::listingCompletionRatio(core) < 1 }
            .sort_by{|core| NxCores::listingCompletionRatio(core) }
            .map{|core| Pure::pure2(core) }
            .flatten
    end
end
