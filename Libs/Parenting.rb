
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

    # Parenting::interativelyMakeNewChildOrNull()
    def self.interativelyMakeNewChildOrNull()
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["task", "pool", "stack"])
        return nil if option.nil?
        if option == "task" then
            return NxTasks::interactivelyMakeOrNull()
        end
        if option == "pool" then
            return TxPools::interactivelyMakeOrNull()
        end
        if option == "stack" then
            return TxStacks::interactivelyMakeOrNull()
        end
    end

    # Parenting::interactivelyIssueChildOrNothing(parent)
    def self.interactivelyIssueChildOrNothing(parent)
        supportedParentTypes = ["NxCore", "TxPool", "TxStack"]
        if !supportedParentTypes.include?(parent["mikuType"]) then
            raise "Unsupported parent type: #{parent["mikuType"]}"
        end
        child = Parenting::interativelyMakeNewChildOrNull()
        return if child.nil?
        if parent["mikuType"] == "NxCore" then
            position = NxCores::interactivelySelectPositionAmongTop(parent)
            Parenting::set_objects(parent, child, position)
        end
        if parent["mikuType"] == "TxPool" then
            Parenting::set_objects(parent, child, 0)
        end
        if parent["mikuType"] == "TxStack" then
            position = TxStacks::interactivelySelectPosition(parent)
            Parenting::set_objects(parent, child, position)
        end
        DarkEnergy::commit(child)
    end

    # Parenting::children(parent)
    def self.children(parent)
        parent["children"]
            .map{|tx8| DarkEnergy::itemOrNull(tx8["childuuid"]) }
            .compact
    end

    # Parenting::children_ordered(parent)
    def self.children_ordered(parent)
        parent["children"]
            .sort_by{|tx8| tx8["position"] }
            .map{|tx8| DarkEnergy::itemOrNull(tx8["childuuid"]) }
            .compact
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
        DarkEnergy::mikuType("TxEdge")
            .select{|edge| edge["parentuuid"] == parent["uuid"] }
            .map{|edge| edge["position"] }
            .compact
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
end
