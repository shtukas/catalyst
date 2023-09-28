 
# encoding: UTF-8

class LStack

    # LStack::newFirstPositionInLStack()
    def self.newFirstPositionInLStack()
        t = Catalyst::catalystItems()
                .select{|item| item["lstack-position"] }
                .map{|item| item["lstack-position"] }
                .reduce(0){|number, x| [number, x].min}
        t - 1
    end

    # LStack::newNextPositionInLStack()
    def self.newNextPositionInLStack()
        t = Catalyst::catalystItems()
                .select{|item| item["lstack-position"] }
                .map{|item| item["lstack-position"] }
                .reduce(0){|number, x| [number, x].max }
        t + 1
    end

    # LStack::stackify(items)
    def self.stackify(items)
        items
            .map{|item|
                if item["lstack-position"].nil? then
                    pos = LStack::newNextPositionInLStack()
                    Events::publishItemAttributeUpdate(item["uuid"], "lstack-position", pos)
                    item["lstack-position"] = pos
                end
                item
            }
            .sort_by{|item| item["lstack-position"] }
    end
end
