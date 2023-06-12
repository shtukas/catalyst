
class TxEdges

    # TxEdges::make(parentuuid, childuuid, position = nil)
    def self.make(parentuuid, childuuid, position = nil)
        {
            "uuid"       => SecureRandom.uuid,
            "mikuType"   => "TxEdge",
            "parentuuid" => parentuuid,
            "childuuid"  => childuuid,
            "position"   => position
        }
    end

    # TxEdges::issueEdge(parent, child, position = nil)
    def self.issueEdge(parent, child, position = nil)
        edge = TxEdges::make(parent["uuid"], child["uuid"], position = nil)
        DarkEnergy::commit(edge)
        edge
    end

    # TxEdges::interativelyMakeNewChildOrNull()
    def self.interativelyMakeNewChildOrNull()
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["task", "pool", "stack"])
        return nil if option
        if option == "task" then
            return NxTasks::interactivelyMakeOrNull()
        end
        if option == "pool" then
            return TxPools::interactivelyMakeOrNull()
        end
        if option == "stack" then
            return TxStacks::interactivelyMakeOrNull()
        end
        child
    end

    # TxEdges::interactivelyIssueChildOrNothing(parent)
    def self.interactivelyIssueChildOrNothing(parent)
        supportedParentTypes = ["NxCore", "TxPool", "TxStack"]
        if !supportedParentTypes.include?(parent["mikuType"]) then
            raise "Unsupported parent type: #{parent["mikuType"]}"
        end
        child = TxEdges::interativelyMakeNewChildOrNull()
        if parent["mikuType"] == "NxCore" then
            position = NxCores::interactivelySelectPositionAmongTop(parent)
            TxEdges::issueEdge(parent, child, position)
        end
        if parent["mikuType"] == "TxPool" then
            TxEdges::issueEdge(parent, child, nil)
        end
        if parent["mikuType"] == "TxStack" then
            position = TxStacks::interactivelySelectPosition(parent)
            TxEdges::issueEdge(parent, child, position)
        end
        DarkEnergy::commit(child)
    end

    # TxEdges::children(parent)
    def self.children(parent)
        DarkEnergy::mikuType("TxEdge")
            .select{|edge| edge["parentuuid"] == parent["uuid"] }
            .map{|edge| DarkEnergy::itemOrNull(edge["childuuid"]) }
            .compact
    end

    # TxEdges::children_ordered(parent)
    def self.children_ordered(parent)
        DarkEnergy::mikuType("TxEdge")
            .select{|edge| edge["parentuuid"] == parent["uuid"] }
            .sort{|edge| edge["position"] || 0 }
            .map{|edge| DarkEnergy::itemOrNull(edge["childuuid"]) }
            .compact
    end

    # TxEdges::getPositionOrNull(parent, child)
    def self.getPositionOrNull(parent, child)
        Memoize::evaluate(
            "1b917287-6118-48f7-8a56-6f988f0f2836:#{parent["uuid"]}:#{child["uuid"]}",
            lambda { 
                entry = DarkEnergy::mikuType("TxEdge")
                    .select{|edge| edge["parentuuid"] == parent["uuid"] }
                    .select{|edge| edge["childuuid"] == child["uuid"] }
                    .first
                return nil if entry.nil?
                entry["position"]
            },
            86400
        )
    end

    # TxEdges::parentChild(px, cx)
    def self.parentChild(px, cx)
        parent = TxEdges::getParentOrNull(cx)
        return false if parent.nil?
        parent["uuid"] == px["uuid"]
    end

    # TxEdges::getParentOrNull(item)
    def self.getParentOrNull(item)
        # Technically an item can have several parents, but practically that won't happen
        DarkEnergy::mikuType("TxEdge")
            .select{|edge| edge["childuuid"] == item["uuid"] }
            .map{|edge| DarkEnergy::itemOrNull(edge["parentuuid"]) }
            .compact
            .first
    end

    # TxEdges::interativelyMakeNewContainerOrNull()
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

    # TxEdges::liftAttempt(item)
    def self.liftAttempt(item)
        container = TxEdges::interativelyMakeNewContainerOrNull()
        return if container.nil?
        container["uuid"] = item["uuid"]
        item["uuid"] = SecureRandom.uuid
        DarkEnergy::commit(item) # we put the item first because if we put the container first and the item commit fails, we lose the item
        DarkEnergy::commit(container)
    end
end
