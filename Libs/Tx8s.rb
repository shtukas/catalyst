
class Tx8s

    # Tx8s::make(uuid, position)
    def self.make(uuid, position)
        {
            "uuid"     => uuid,
            "position" => position
        }
    end

    # Tx8s::mikuTypeToEmoji(type)
    def self.mikuTypeToEmoji(type)
        return "⛵️" if type == "NxNode"
        return "☕️" if type == "NxCore"
        "🤔"
    end

    # Tx8s::parentSuffix(item)
    def self.parentSuffix(item)
        return "" if item["parent"].nil?
        parent = DarkEnergy::itemOrNull(item["parent"]["uuid"])
        return "" if parent.nil?
        suffix2 = (parent["mikuType"] == "NxNode" ? Tx8s::parentSuffix(parent) : "")
        " (#{Tx8s::mikuTypeToEmoji(parent["mikuType"])} #{parent["description"].green})#{suffix2}"
    end

    # Tx8s::children_in_order(element)
    def self.children_in_order(element)
        DarkEnergy::all()
            .select{|item| item["parent"] }
            .select{|item| item["parent"]["uuid"] == element["uuid"] }
            .sort_by{|item| item["parent"]["position"] }
    end

    # Tx8s::childrenPositions(element)
    def self.childrenPositions(element)
        Tx8s::children_in_order(element)
            .map{|item| item["parent"]["position"] }
    end

    # Tx8s::childrenNodes(element)
    def self.childrenNodes(element)
        Tx8s::children_in_order(element)
            .select{|item| item["mikuType"] == "NxNode" }
    end

    # Tx8s::repositionAtSameParent(item)
    def self.repositionAtSameParent(item)
        return if item["parent"].nil?
        parent = DarkEnergy::itemOrNull(item["parent"]["uuid"])
        return if parent.nil?
        if parent["mikuType"] == "NxNode" then
            position = NxNodes::interactivelyDecidePositionInNode(parent)
            item["parent"]["position"] = position
            DarkEnergy::commit(item)
            return
        end
        if parent["mikuType"] == "NxCore" then
            position = NxCores::interactivelyDecidePositionInCore(parent)
            item["parent"]["position"] = position
            DarkEnergy::commit(item)
            return
        end
        raise "I do not know how to Tx8s::repositionAtSameParent item: #{item}"
    end

    # Tx8s::determinePositionAtContainer(container)
    def self.determinePositionAtContainer(container)
        # A container is a NxCore or a NxNode
        if container["mikuType"] == "NxCore" then
            return NxCores::interactivelyDecidePositionInCore(container)
        end
        if container["mikuType"] == "NxNode" then
            return NxNodes::interactivelyDecidePositionInNode(container)
        end
        raise "I cannot Tx8s::determinePositionAtContainer with container: #{container}"
    end

    # Tx8s::interactivelyMakeNewTx8BelowThisElementOrNull(parent)
    def self.interactivelyMakeNewTx8BelowThisElementOrNull(parent)
        puts "element: #{PolyFunctions::toString(parent).green}"
        puts "children node:"
        Tx8s::children_in_order(parent).each{|node|
            puts "    - #{PolyFunctions::toString(node)}"
        }
        options = ["put here", "go deeper", "issue new child node", "exit"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        if option.nil? then
            return Tx8s::interactivelyMakeNewTx8BelowThisElementOrNull(parent)
        end
        if option == "put here" then
            position = Tx8s::determinePositionAtContainer(parent)
            return Tx8s::make(parent["uuid"], position)
        end
        if option == "go deeper" then
            nodes = Tx8s::childrenNodes(parent)
            node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nodes, lambda{|item| PolyFunctions::toString(item) })
            if node.nil? then
                return Tx8s::interactivelyMakeNewTx8BelowThisElementOrNull(parent)
            else
                return Tx8s::interactivelyMakeNewTx8BelowThisElementOrNull(node)
            end
        end
        if option == "issue new child node" then
            node = NxNodes::interactivelyIssueNewOrNull()
            position = Tx8s::determinePositionAtContainer(parent)
            node["parent"] = Tx8s::make(parent["uuid"], position)
            DarkEnergy::commit(node)
            Tx8s::interactivelyMakeNewTx8BelowThisElementOrNull(node)
        end
        if option == "exit" then
            return nil
        end
    end

    # Tx8s::interactivelyMakeNewTx8OrNull()
    def self.interactivelyMakeNewTx8OrNull()
        # This function returns a Tx8
        core = NxCores::interactivelySelectOneOrNull()
        if core then
            Tx8s::interactivelyMakeNewTx8BelowThisElementOrNull(core)
        else
            nil
        end
    end

    # Tx8s::setContext(item)
    def self.setContext(item)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["move", "engine", "deadline"])
        return if option.nil?
        if option == "move" then
            DarkEnergy::patch(item["uuid"], "parent", Tx8s::interactivelyMakeNewTx8OrNull())
        end
        if option == "engine" then
            NxEngines::attachEngineAttempt(item)
        end
        if option == "deadline" then
            NxDeadlines::attachDeadlineAttempt(item)
        end
    end
end
