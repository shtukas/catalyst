

class Catalyst

    # Catalyst::listingCompletionRatio(item)
    def self.listingCompletionRatio(item)
        if item["mikuType"] == "NxTask" then
            return Bank::recoveredAverageHoursPerDay(item["uuid"])
        end
        if item["mikuType"] == "TxCore" then
            hours = item["hours"]
            return Bank::recoveredAverageHoursPerDay(item["uuid"]).to_f/(hours.to_f/6)
        end
        raise "(error: 3b1e3b09-1472-48ef-bcbb-d98c8d170056) with item: #{item}"
    end

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Events::publishItemAttributeUpdate(item["uuid"], key, value)
        }
    end

    # Catalyst::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        EventTimelineDatasets::catalystItems()[uuid].clone
    end

    # Catalyst::mikuType(mikuType)
    def self.mikuType(mikuType)
        EventTimelineDatasets::catalystItems().values.select{|item| item["mikuType"] == mikuType }
    end

    # Catalyst::destroy(uuid)
    def self.destroy(uuid)
        Events::publishItemDestroy(uuid)
    end

    # Catalyst::catalystItems()
    def self.catalystItems()
        EventTimelineDatasets::catalystItems().values
    end

    # Catalyst::newGlobalFirstPosition()
    def self.newGlobalFirstPosition()
        t = Catalyst::catalystItems()
                .select{|item| item["global-position"] }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].min}
        t - 1
    end

    # Catalyst::newGlobalLastPosition()
    def self.newGlobalLastPosition()
        t = Catalyst::catalystItems()
                .select{|item| item["global-position"] }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].max }
        t + 1
    end

    # Catalyst::enginedInOrder()
    def self.enginedInOrder()
        Catalyst::catalystItems()
            .select{|item| item["engine-2251"] }
            .sort_by{|item| TxEngine::ratio(item["engine-2251"]) }
    end

    # Catalyst::starredInOrder()
    def self.starredInOrder()
        Catalyst::catalystItems()
            .select{|item| item["star-0936"] }
            .sort_by{|item| item["global-position"] || 0 }
    end

    # Catalyst::enginedInOrderForListing()
    def self.enginedInOrderForListing()
        Catalyst::enginedInOrder()
            .select{|item| TxEngine::ratio(item["engine-2251"]) < 1 }
    end

    # Catalyst::activeBurnerForefrontsInOrder()
    def self.activeBurnerForefrontsInOrder()
        Catalyst::catalystItems()
            .select{|item| item["engine-2251"] and item["engine-2251"]["type"] == "active-burner-forefront" }
            .sort_by{|item| item["global-position"] || 0 }
    end

    # Catalyst::appendAtEndOfChildrenSequence(parent, item)
    def self.appendAtEndOfChildrenSequence(parent, item)
        Events::publishItemAttributeUpdate(item["uuid"], "parent-1328", parent["uuid"])
        Events::publishItemAttributeUpdate(item["uuid"], "global-position", Catalyst::newGlobalLastPosition())
    end

    # Catalyst::prependAtBeginingOfChildrenSequence(parent, item)
    def self.prependAtBeginingOfChildrenSequence(parent, item)
        Events::publishItemAttributeUpdate(item["uuid"], "parent-1328", parent["uuid"])
        Events::publishItemAttributeUpdate(item["uuid"], "global-position", Catalyst::newGlobalFirstPosition())
    end

    # Catalyst::pile3(item)
    def self.pile3(item)
        if item["mikuType"] == "NxCore" then
            TxCores::pile3(core)
            return
        end
        puts "Piling on elements of '#{PolyFunctions::toString(item)}'"
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.uuid, line)
                puts JSON.pretty_generate(task)
                Catalyst::prependAtBeginingOfChildrenSequence(item, task)
            }
    end

    # Catalyst::elementsInOrder(parent)
    def self.elementsInOrder(parent)
        Catalyst::catalystItems()
            .select{|item| item["parent-1328"] == parent["uuid"] }
            .sort_by {|item| item["global-position"] }
    end

    # Catalyst::program1(parent)
    def self.program1(parent)
        loop {

            parent = Catalyst::itemOrNull(parent["uuid"])
            return if parent.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(parent, false)
            puts  Listing::toString2(store, parent)
            puts  ""

            Catalyst::elementsInOrder(parent)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  "(#{"%6.2f" % (item["global-position"] || 0)}) #{Listing::toString2(store, item)}"
                }

            puts ""
            puts "task | pile | sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Events::publishItemAttributeUpdate(task["uuid"], "parent-1328", parent["uuid"])
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                Events::publishItemAttributeUpdate(item["uuid"], "global-position", position)
                next
            end

            if input == "pile" then
                Catalyst::pile3(parent)
                next
            end

            if input == "sort" then
                items = Catalyst::elementsInOrder(parent)
                selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    Events::publishItemAttributeUpdate(item["uuid"], "global-position", Catalyst::newGlobalFirstPosition())
                }
                next
            end

            if input == "move" then
                Catalyst::selectSubsetAndMoveToSelectedParent(TxCores::childrenInOrder(parent))
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Catalyst::program2(elements)
    def self.program2(elements)
        loop {

            elements = elements.map{|item| Catalyst::itemOrNull(item["uuid"]) }.compact
            return if elements.empty?

            system("clear")

            store = ItemStore.new()

            puts  ""

            elements
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            puts "task | pile | sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                puts "task is not defined in this context"
                LucilleCore::pressEnterToContinue()
                next
            end

            if input == "pile" then
                puts "pile is not defined in this context"
                LucilleCore::pressEnterToContinue()
                next
            end

            if input == "sort" then
                puts "sort is not defined in this context"
                LucilleCore::pressEnterToContinue()
                next
            end

            if input == "move" then
                Catalyst::selectSubsetAndMoveToSelectedParent(elements)
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Catalyst::setDrivingForce(item)
    def self.setDrivingForce(item)
        options = [
            "stack (top position)",
            "engine",
            "active (will show in active listing)",
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        return option.nil?
        if option == "stack (top position)" then
            Events::publishItemAttributeUpdate(item["uuid"], "stack-0012", [CommonUtils::today(), DxStack::newFirstPosition()])
        end
        if option == "engine" then
            engine = TxEngine::interactivelyMakeOrNull()
            return if engine.nil?
            Events::publishItemAttributeUpdate(item["uuid"], "engine-2251", engine)
        end
        if option == "active (will show in active listing)" then
            Events::publishItemAttributeUpdate(item["uuid"], "active-1634", true)
        end
    end

    # Catalyst::interactivelySelectOneItemOrNull(items)
    def self.interactivelySelectOneItemOrNull(items)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| PolyFunctions::toString(item) })
    end

    # Catalyst::interactivelySelectGenericMoveParentOrNull()
    def self.interactivelySelectGenericMoveParentOrNull()
        items = (Catalyst::starredInOrder() + TxCores::coresInOrder() + NxOndates::ondatesInOrder()+ Catalyst::activeBurnerForefrontsInOrder() + Catalyst::enginedInOrder())
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
        Catalyst::interactivelySelectOneItemOrNull(items)
    end

    # Catalyst::selectSubsetAndMoveToSelectedParent(items)
    def self.selectSubsetAndMoveToSelectedParent(items)
        selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.empty?
        parent = Catalyst::interactivelySelectGenericMoveParentOrNull()
        return if parent.nil?
        selected.each{|item|
            Events::publishItemAttributeUpdate(item["uuid"], "parent-1328", parent["uuid"])
        }
    end
end
