
class Tx8s

    # Tx8s::make(uuid, position)
    def self.make(uuid, position)
        {
            "uuid"     => uuid,
            "position" => position
        }
    end

    # Tx8s::childrenInOrder(parent)
    def self.childrenInOrder(parent)
        DarkEnergy::all()
            .select{|item| item["parent"] }
            .select{|item| item["parent"]["uuid"] == parent["uuid"] }
            .sort_by{|item| item["parent"]["position"] }
    end

    # Tx8s::repositionItemAtSameParent(item)
    def self.repositionItemAtSameParent(item)
        return if item["parent"].nil?
        parent = DarkEnergy::itemOrNull(item["parent"]["uuid"])
        return if parent.nil?
        position = Tx8s::interactivelyDecidePositionUnderThisParent(parent)
        item["parent"]["position"] = position
        DarkEnergy::commit(item)
    end

    # Tx8s::interactivelyDecidePositionUnderThisParent(parent)
    def self.interactivelyDecidePositionUnderThisParent(parent)
        children = Tx8s::childrenInOrder(parent)
        return 1 if children.empty?
        children.each{|item|
            puts " - #{PolyFunctions::toString(item)}"
        }
        position = LucilleCore::askQuestionAnswerAsString("> position (empty for next): ")
        if position == "" then
            positions = Tx8s::childrenInOrder(parent).map{|item| item["parent"]["position"] }
            return 1 if positions.empty?
            return positions.max + 1
        else
            return position.to_f
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

    # Tx8s::newFirstPositionAtThisParent(parent)
    def self.newFirstPositionAtThisParent(parent)
        ([0] + Tx8s::childrenInOrder(parent).map{|item| item["parent"]["position"] }).min - 1
    end

    # Tx8s::interactivelyMakeTx8AtParentOrNull(parent)
    def self.interactivelyMakeTx8AtParentOrNull(parent)
        position = Tx8s::interactivelyDecidePositionUnderThisParent(parent)
        Tx8s::make(parent["uuid"], position)
    end

    # Tx8s::interactivelyPutIntoParentAttempt(item, parent)
    def self.interactivelyPutIntoParentAttempt(item, parent)
        tx8 = Tx8s::interactivelyMakeTx8AtParentOrNull(parent)
        return if tx8.nil?
        DarkEnergy::patch(item["uuid"], "parent", tx8)
    end

    # Tx8s::getParentOrNull(item)
    def self.getParentOrNull(item)
        return nil if item["parent"].nil?
        DarkEnergy::itemOrNull(item["parent"]["uuid"])
    end
end
