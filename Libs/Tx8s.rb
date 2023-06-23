
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
        return "☕️" if type == "NxCore"
        "🤔"
    end

    # Tx8s::parentSuffix(item)
    def self.parentSuffix(item)
        return "" if item["parent"].nil?
        parent = DarkEnergy::itemOrNull(item["parent"]["uuid"])
        return "" if parent.nil?
        " (#{Tx8s::mikuTypeToEmoji(parent["mikuType"])} #{parent["description"].green})#{Tx8s::parentSuffix(parent)}"
    end

    # Tx8s::childrenInOrder(element)
    def self.childrenInOrder(element)
        DarkEnergy::all()
            .select{|item| item["parent"] }
            .select{|item| item["parent"]["uuid"] == element["uuid"] }
            .sort_by{|item| item["parent"]["position"] }
    end

    # Tx8s::childrenPositions(element)
    def self.childrenPositions(element)
        Tx8s::childrenInOrder(element)
            .map{|item| item["parent"]["position"] }
    end

    # Tx8s::repositionAtSameParent(item)
    def self.repositionAtSameParent(item)
        position = Tx8s::interactivelyDecidePositionUnderThisParent(container)
        item["parent"]["position"] = position
        DarkEnergy::commit(item)
    end

    # Tx8s::interactivelyDecidePositionUnderThisParent(parent)
    def self.interactivelyDecidePositionUnderThisParent(parent)
        NxCores::children(parent)
            .each{|item|
                puts " - #{PolyFunctions::toString(item)}"
            }
        position = LucilleCore::askQuestionAnswerAsString("> position (empty for next): ")
        if position == "" then
            positions = Tx8s::childrenPositions(parent)
            return 1 if positions.empty?
            return positions.max + 1
        else
            return position.to_f
        end
    end

    # Tx8s::interactivelyMakeNewTx8BelowThisElement(parent)
    def self.interactivelyMakeNewTx8BelowThisElement(parent)
        puts "element: #{PolyFunctions::toString(parent).green}"
        puts "children node:"
        Tx8s::childrenInOrder(parent).each{|node|
            puts "    - #{PolyFunctions::toString(node)}"
        }
        position = Tx8s::interactivelyDecidePositionUnderThisParent(parent)
        Tx8s::make(parent["uuid"], position)
    end

    # Tx8s::interactivelyMakeNewTx8OrNull()
    def self.interactivelyMakeNewTx8OrNull()
        # This function returns a Tx8
        core = NxCores::interactivelySelectOneOrNull()
        if core then
            Tx8s::interactivelyMakeNewTx8BelowThisElement(core)
        else
            nil
        end
    end

    # Tx8s::interactivelyDecideAndSetParent(item)
    def self.interactivelyDecideAndSetParent(item)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["core", "engine", "deadline"])
        return if option.nil?
        if option == "core" then
            DarkEnergy::patch(item["uuid"], "parent", Tx8s::interactivelyMakeNewTx8OrNull())
        end
        if option == "engine" then
            NxEngines::attachEngineAttempt(item)
        end
        if option == "deadline" then
            NxDeadlines::attachDeadlineAttempt(item)
        end
    end

    # Tx8s::reorganise(item)
    def self.reorganise(item)
        children = Tx8s::childrenInOrder(item)
                    .select{|i| i["mikuType"] == "NxTask" }
        if children.size < 2 then
            puts "item has #{children.size} children, nothing to organise"
            LucilleCore::pressEnterToContinue()
            return
        end

        sorted = []
        unsorted = children

        while unsorted.size > 0 do
            system('clear')
            puts "sorted:"
            sorted.each{|i|
                puts "    - #{PolyFunctions::toString(i)}"
            }
            puts "unsorted:"
            i = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", unsorted, lambda{|i| PolyFunctions::toString(i) })
            next if i.nil?
            sorted << i
            unsorted = unsorted.reject{|x| x["uuid"] == i["uuid"]}
        end

        puts "final:"
        sorted.each{|i|
            puts "    - #{PolyFunctions::toString(i)}"
        }

        LucilleCore::pressEnterToContinue()
        sorted.each_with_index{|i, indx|
            i["parent"]["position"] = indx+1
            puts JSON.pretty_generate(i)
            DarkEnergy::commit(i)
        }
    end
end
