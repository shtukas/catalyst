
class Prefix
    # Prefix::addPrefix(items)
    def self.addPrefix(items)
        return [] if items.empty?
        if items[0]["mikuType"] == "NxThread" then
            children = Catalyst::children(items[0])
            children = children.sort_by{|i| (i["global-positioning"] || 0) }
            if children.empty? then
                return items
            end
            children = children.map{|child|
                if child["mikuType"] == "NxThread" then
                    if NxThreads::ratio(child) < 1 then
                        child
                    else
                        nil
                    end
                else
                    child
                end
            }.compact
            return Prefix::addPrefix(children.take(3) + items)
        end
        return items
    end
end
