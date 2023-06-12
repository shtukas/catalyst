
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

    # TxEdges::interativelyIssueNewChildOrNull()
    def self.interativelyIssueNewChildOrNull()
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["task", "pool", "stack"])
        return nil if option
        if option == "task" then
            child = NxTasks::interactivelyIssueNewOrNull()
            return nil if child.nil?
        end
        if option == "pool" then
            child = TxPools::interactivelyIssueNewOrNull()
            return nil if child.nil?
        end
        if option == "stack" then
            child = TxStacks::interactivelyIssueNewOrNull()
            return nil if child.nil?
        end
        child
    end

    # TxEdges::interactivelyIssueChildOrNothing(parent)
    def self.interactivelyIssueChildOrNothing(parent)
        supportedParentTypes = ["NxCore", "TxPool", "TxStack"]
        if !supportedParentTypes.include?(parent["mikuType"]) then
            raise "Unsupported parent type: #{parent["mikuType"]}"
        end
        child = TxEdges::interativelyIssueNewChildOrNull()
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
        entry = DarkEnergy::mikuType("TxEdge")
            .select{|edge| edge["parentuuid"] == parent["uuid"] }
            .select{|edge| edge["childuuid"] == child["uuid"] }
            .first
        return nil if entry.nil?
        entry["position"]
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
end
