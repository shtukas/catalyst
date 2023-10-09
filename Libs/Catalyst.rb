

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
            Broadcasts::publishItemAttributeUpdate(item["uuid"], key, value)
        }
    end

    # Catalyst::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        return $ItemsOperator.itemOrNull(uuid)

        item = nil
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Items.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items where _uuid_=?", [uuid]) do |row|
            item = JSON.parse(row["_item_"])
        end
        db.close
        item
    end

    # Catalyst::mikuType(mikuType)
    def self.mikuType(mikuType)
        return $ItemsOperator.mikuType(mikuType)

        items = []
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Items.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items where _mikuType_=?", [mikuType]) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items
    end

    # Catalyst::destroy(uuid)
    def self.destroy(uuid)
        Broadcasts::publishItemDestroy(uuid)
    end

    # Catalyst::catalystItems()
    def self.catalystItems()
        return $ItemsOperator.all()

        items = []
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Items.sqlite3"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from Items", []) do |row|
            items << JSON.parse(row["_item_"])
        end
        db.close
        items
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

    # Catalyst::redInOrder()
    def self.redInOrder()
        Catalyst::catalystItems()
            .select{|item| item["red-2029"] }
            .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
    end

    # Catalyst::appendAtEndOfChildrenSequence(parent, item)
    def self.appendAtEndOfChildrenSequence(parent, item)
        Broadcasts::publishItemAttributeUpdate(item["uuid"], "parent-1328", parent["uuid"])
        Broadcasts::publishItemAttributeUpdate(item["uuid"], "global-position", Catalyst::newGlobalLastPosition())
    end

    # Catalyst::prependAtBeginingOfChildrenSequence(parent, item)
    def self.prependAtBeginingOfChildrenSequence(parent, item)
        Broadcasts::publishItemAttributeUpdate(item["uuid"], "parent-1328", parent["uuid"])
        Broadcasts::publishItemAttributeUpdate(item["uuid"], "global-position", Catalyst::newGlobalFirstPosition())
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

    # Catalyst::children(parent)
    def self.children(parent)
        Catalyst::catalystItems()
            .select{|item| item["parent-1328"] == parent["uuid"] }
            .sort_by{|item| item["global-position"] || 0 }
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

            Catalyst::children(parent)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  "(#{"%6.2f" % (item["global-position"] || 0)}) #{Listing::toString2(store, item)}"
                }

            puts ""
            puts "task | pile | position * |sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Broadcasts::publishItemAttributeUpdate(task["uuid"], "parent-1328", parent["uuid"])
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                Broadcasts::publishItemAttributeUpdate(task["uuid"], "global-position", position)
                next
            end

            if input == "pile" then
                Catalyst::pile3(parent)
                next
            end

            if Interpreting::match("position *", input) then
                _, listord = Interpreting::tokenizer(input)
                item = store.get(listord.to_i)
                next if item.nil?
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                Broadcasts::publishItemAttributeUpdate(item["uuid"], "global-position", position)
                next
            end

            if input == "sort" then
                items = Catalyst::children(parent)
                selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    Broadcasts::publishItemAttributeUpdate(item["uuid"], "global-position", Catalyst::newGlobalFirstPosition())
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
            "red mark",
            "interactively select parent"
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        return if option.nil?
        if option == "stack (top position)" then
            position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "stack-0012", [CommonUtils::today(), position])
        end
        if option == "red mark" then
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "red-2029", true)
            Catalyst::setDrivingForce(item)
        end
        if option == "interactively select parent" then
            parent = Catalyst::interactivelySelectParentOrNullUsingTopDownNavigation(nil)
            if parent then
                Broadcasts::publishItemAttributeUpdate(item["uuid"], "parent-1328", parent)
            end
            Catalyst::setDrivingForce(item)
        end
    end

    # Catalyst::interactivelySelectOneItemOrNull(items)
    def self.interactivelySelectOneItemOrNull(items)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| PolyFunctions::toString(item) })
    end

    # Catalyst::interactivelySelectParentOrNullUsingTopDownNavigation(context)
    def self.interactivelySelectParentOrNullUsingTopDownNavigation(context)
        if context.nil? then
            options = ["no parent (default)", "select core"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            if option.nil? or option == "no parent (default)" then
                return nil
            end
            if option == "select core" then
                core = TxCores::interactivelySelectOneOrNull()
                if core then
                    return Catalyst::interactivelySelectParentOrNullUsingTopDownNavigation(core)
                else
                    return Catalyst::interactivelySelectParentOrNullUsingTopDownNavigation(nil)
                end
            end
        else
            return context
        end
    end

    # Catalyst::selectSubsetAndMoveToSelectedParent(items)
    def self.selectSubsetAndMoveToSelectedParent(items)
        selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.empty?
        parent = Catalyst::interactivelySelectParentOrNullUsingTopDownNavigation()
        return if parent.nil?
        selected.each{|item|
            Broadcasts::publishItemAttributeUpdate(item["uuid"], "parent-1328", parent["uuid"])
        }
    end
end
