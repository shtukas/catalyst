
class Pure

    # Pure::pure(item) # item -> peek + [item]
    def self.pure(item)
        if item["mikuType"] == "NxCollection" then
            is = Tx8s::childrenInOrder(item)
            if is.size > 0 then
                return Pure::pure(is.first) + [item]
            end
            return [item]
        end
        if item["mikuType"] == "DxAntimatter" then
            core = DarkEnergy::itemOrNull(item["familyId"])
            if core.nil? then
                puts "At Pure::pure, I could not find a core for item: #{item}"
                exit
            end
            collections = Tx8s::childrenInOrder(core).select{|i| i["mikuType"] == "NxCollection" }
            if collections.size > 0 then
                collections.each{|collection|
                    if NxCollections::completionRatio(collection) < 1 and Tx8s::childrenInOrder(collection).size > 0 then
                        return Pure::pure(collection) + [item]
                    end
                }
            end
            is = Tx8s::childrenInOrder(core).select{|i| i["mikuType"] == "NxTask" }
            if is.size > 0 then
                return [is.first] + [item]
            end
            return [item]
        end
        [item]
    end

    # Pure::energy(items)
    def self.energy(items)
        [
            items
                .take(3)
                .map{|item| Pure::pure(item)}
                .flatten,
            items.drop(3)
        ].flatten
    end
end
