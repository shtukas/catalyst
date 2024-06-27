# encoding: UTF-8

class Cx11s

    # Cx11s::setCondition(item, cx11)
    def self.setCondition(item, cx11)
        Items::setAttribute(item["uuid"], "condition-0903", cx11)
    end

    # Cx11s::dropCondition(item)
    def self.dropCondition(item)
        return if item["condition-0903"].nil?
        Items::setAttribute(item["uuid"], "condition-0903", nil)
    end

    # Cx11s::collectDistinctCx11sFromItems(items)
    def self.collectDistinctCx11sFromItems(items)
        items.map{|item| item["condition-0903"] }.compact.reduce([]){|collection, cx11|
            if collection.map{|x| x["name"] }.include?(cx11["name"]) then
                collection
            else
                collection + [cx11]
            end
        }
    end

    # Cx11s::getItemsByConditionName(items, name1)
    def self.getItemsByConditionName(items, name1)
        items.select{|item| item["condition-0903"] and item["condition-0903"]["name"] == name1 }
    end

    # Cx11s::toString(cx11)
    def self.toString(cx11)
        "#{cx11["name"]} (#{cx11["status"]})"
    end

    # Cx11s::architectNewOrNull()
    def self.architectNewOrNull()
        cx11s = Cx11s::collectDistinctCx11sFromItems(Items::items())
        if cx11s.size > 0 then
            cx11 = LucilleCore::selectEntityFromListOfEntitiesOrNull("cx11", cx11s, lambda{|item| Cx11s::toString(item) })
            return cx11 if cx11
        end
        name1 = LucilleCore::askQuestionAnswerAsString("condition name: ")
        return nil if name1 == ""
        {
            "name"   => name1,
            "status" => false
        }
    end

    # Cx11s::itemShouldBeListed(item)
    def self.itemShouldBeListed(item)
        return true if item["condition-0903"].nil?
        item["condition-0903"]["status"]
    end

    # Cx11s::interactivelySelectCx11OrNull()
    def self.interactivelySelectCx11OrNull()
        cx11s = Cx11s::collectDistinctCx11sFromItems(Items::items())
        LucilleCore::selectEntityFromListOfEntitiesOrNull("cx11", cx11s, lambda{|item| Cx11s::toString(item) })
    end
end
