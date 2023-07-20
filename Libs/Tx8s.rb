
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
        children = nil
        if parent["mikuType"] == "TxCore" or parent["mikuType"] == "NxThread" then
            children = Tx8s::childrenInOrder(parent)
                .select{|item| item["mikuType"] == "NxTask" }
                .take(CommonUtils::screenHeight() - 4)
        end
        if children.nil? then
            children = Tx8s::childrenInOrder(parent)
                .take(CommonUtils::screenHeight() - 4)
        end
        return 1 if children.empty?
        puts "positioning:"
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
        garbageCollected = []

        while unsorted.size > 0 do
            system('clear')
            puts ""
            puts "sorted:"
            sorted.each{|i|
                puts "    - #{PolyFunctions::toString(i)}"
            }
            puts ""
            puts "garbage collected:"
            garbageCollected.each{|i|
                puts "    - #{PolyFunctions::toString(i)}"
            }
            puts ""
            puts "unsorted:"
            i = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", unsorted, lambda{|i| PolyFunctions::toString(i) })
            next if i.nil?
            command = LucilleCore::askQuestionAnswerAsString("> command (keep, destroy, run+destroy): ")
            if command == "keep" then
                sorted << i
                unsorted = unsorted.reject{|x| x["uuid"] == i["uuid"]}
            end
            if command == "destroy" then
                garbageCollected << i
                unsorted = unsorted.reject{|x| x["uuid"] == i["uuid"]}
            end
            if command == "run+destroy" then
                puts "starting and running"
                NxBalls::start(item)
                PolyActions::access(item)
                LucilleCore::pressEnterToContinue("Press enter to garbage collect")
                garbageCollected << i
                unsorted = unsorted.reject{|x| x["uuid"] == i["uuid"]}
            end
        end

        puts ""
        puts "final:"
        sorted.each{|i|
            puts "    - #{PolyFunctions::toString(i)}"
        }

        puts ""
        puts "going to be destroyed:"
        garbageCollected.each{|i|
            puts "    - #{PolyFunctions::toString(i)}"
        }

        puts ""
        LucilleCore::pressEnterToContinue()
        sorted.each_with_index{|i, indx|
            i["parent"]["position"] = indx+1
            puts JSON.pretty_generate(i)
            DarkEnergy::commit(i)
        }

        garbageCollected.each{|i|
            DarkEnergy::destroy(i["uuid"])
        }
    end

    # Tx8s::newFirstPositionAtThisParent(parent)
    def self.newFirstPositionAtThisParent(parent)
        ([0] + Tx8s::childrenInOrder(parent).map{|item| item["parent"]["position"] }).min - 1
    end

    # Tx8s::nextPositionAtThisParent(parent)
    def self.nextPositionAtThisParent(parent)
        ([0] + Tx8s::childrenInOrder(parent).map{|item| item["parent"]["position"] }).max + 1
    end

    # Tx8s::interactivelyMakeTx8AtParentOrNull(parent)
    def self.interactivelyMakeTx8AtParentOrNull(parent)
        position = Tx8s::interactivelyDecidePositionUnderThisParent(parent)
        Tx8s::make(parent["uuid"], position)
    end

    # Tx8s::interactivelyPlaceItemAtParentAttempt(item, parent)
    def self.interactivelyPlaceItemAtParentAttempt(item, parent)
        tx8 = Tx8s::interactivelyMakeTx8AtParentOrNull(parent)
        return if tx8.nil?
        DarkEnergy::patch(item["uuid"], "parent", tx8)
    end

    # Tx8s::getParentOrNull(item)
    def self.getParentOrNull(item)
        return nil if item["parent"].nil?
        DarkEnergy::itemOrNull(item["parent"]["uuid"])
    end

    # Tx8s::positionInParentSuffix(item)
    def self.positionInParentSuffix(item)
        return "" if item["parent"].nil?
        " (#{"%5.2f" % item["parent"]["position"]})"
    end

    # Tx8s::pileAtThisParent(parent)
    def self.pileAtThisParent(parent)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text.lines.to_a.map{|line| line.strip }.select{|line| line.size > 0 }.reverse.each {|line|
            t1 = NxTasks::descriptionToTask(line)
            next if t1.nil?
            t1["parent"] = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))
            puts JSON.pretty_generate(t1)
            DarkEnergy::commit(t1)
        }
    end

    # Tx8s::suffix(item)
    def self.suffix(item)
        return "" if item["parent"].nil?
        parent = DarkEnergy::itemOrNull(item["parent"]["uuid"])
        return "" if parent.nil?
        " (#{parent["description"]})"
    end
end
