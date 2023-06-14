
class Parenting

    # Parenting::set_uuids(parentuuid, childuuid, position)
    def self.set_uuids(parentuuid, childuuid, position)
        parent = DarkEnergy::itemOrNull(parentuuid)
        child = DarkEnergy::itemOrNull(childuuid)
        return if parent.nil?
        return if child.nil?
        Parenting::set_objects(parent, child, position)
    end

    # Parenting::set_objects(parent, child, position)
    def self.set_objects(parent, child, position)
        if parent["children"].nil? then
            parent["children"] = []
        end
        parent["children"] = parent["children"].select{|tx8| tx8["childuuid"] != child["uuid"] }
        parent["children"] << {
            "childuuid" => child["uuid"],
            "position"  => position
        }
        child["parent"] = parent["uuid"]
        DarkEnergy::commit(parent)
        DarkEnergy::commit(child)
    end

    # Parenting::children(parent)
    def self.children(parent)
        return [] if parent["children"].nil?
        parent["children"]
            .map{|tx8| DarkEnergy::itemOrNull(tx8["childuuid"]) }
            .compact
    end

    # Parenting::childrenInPositionOrder(parent)
    def self.childrenInPositionOrder(parent)
        return [] if parent["children"].nil?
        parent["children"]
            .sort_by{|tx8| tx8["position"] }
            .map{|tx8| DarkEnergy::itemOrNull(tx8["childuuid"]) }
            .compact
    end

    # Parenting::childrenInRecoveryTimeOrder(parent)
    def self.childrenInRecoveryTimeOrder(parent)
        parent["children"]
            .map{|tx8| DarkEnergy::itemOrNull(tx8["childuuid"]) }
            .compact
            .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
    end

    # Parenting::getPositionOrNull(parent, child)
    def self.getPositionOrNull(parent, child)
        return nil if parent["children"].nil?
        tx8 = parent["children"]
                    .select{|tx8| tx8["childuuid"] == child["uuid"] }
                    .first
        return nil if tx8.nil?
        tx8["position"]
    end

    # Parenting::isParentChild(px, cx)
    def self.isParentChild(px, cx)
        return false if px["children"].nil?
        px["children"].any?{|tx8| tx8["childuuid"] == cx["uuid"] }
    end

    # Parenting::getParentOrNull(item)
    def self.getParentOrNull(item)
        return nil if item["parent"].nil?
        DarkEnergy::itemOrNull(item["parent"])
    end

    # Parenting::interativelyMakeNewContainerOrNull()
    def self.interativelyMakeNewContainerOrNull()
        mikuType = LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", ["TxPool", "TxStack"])
        return nil if mikuType
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => mikuType,
            "description" => description
        }
    end

    # Parenting::childrenPositions(parent)
    def self.childrenPositions(parent)
        return [] if parent["children"].nil?
        parent["children"].map{|tx8| tx8["position"] }
    end

    # Parenting::liftAttempt(item)
    def self.liftAttempt(item)
        container = Parenting::interativelyMakeNewContainerOrNull()
        return if container.nil?
        container["uuid"] = item["uuid"]
        item["uuid"] = SecureRandom.uuid
        DarkEnergy::commit(item) # we put the item first because if we put the container first and the item commit fails, we lose the item
        DarkEnergy::commit(container)
        Parenting::set_objects(container, item, position)
    end

    # Parenting::positionSuffix(item)
    def self.positionSuffix(item)
        position = NxTasks::getItemPositionOrNull(item)
        if position and position != 0 then
            " (#{"%5.2f" % position})"
        else
            ""
        end
    end

    # Parenting::interactivelyDecideRelevantPositionAtParent(parent)
    def self.interactivelyDecideRelevantPositionAtParent(parent)
        if parent["mikuType"] == "NxCore" then
            return Parenting::childrenPositions(parent).reduce(1){|max, i| [max, i].max } + 1
        end
        if parent["mikuType"] == "TxPool" then
            return 0
        end
        if parent["mikuType"] == "TxStack" then
            return TxStacks::interactivelySelectPosition(stack)
        end
        raise "(error: 1d91191d-be7e-42a9-bb9e-0894d545f60f - unsupported mikuType) #{item["mikuType"]} (item: #{item})"
    end

    # Parenting::genealogySuffix(item)
    def self.genealogySuffix(item)
        genealogy = PolyFunctions::genealogy(item)
        (genealogy.size < 2) ? "" : " (#{PolyFunctions::genealogy(item).reverse.join(";")})"
    end
end
