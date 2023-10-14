

class Catalyst

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Updates::itemAttributeUpdate(item["uuid"], key, value)
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
        Updates::itemDestroy(uuid)
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
                .map{|item| item["global-position"] || 0 }
                .reduce(0){|number, x| [number, x].min}
        t - 1
    end

    # Catalyst::newGlobalLastPosition()
    def self.newGlobalLastPosition()
        t = Catalyst::catalystItems()
                .select{|item| item["global-position"] }
                .map{|item| item["global-position"] || 0 }
                .reduce(0){|number, x| [number, x].max }
        t + 1
    end

    # Catalyst::appendAtEndOfChildrenSequence(parent, item)
    def self.appendAtEndOfChildrenSequence(parent, item)
        Updates::itemAttributeUpdate(item["uuid"], "parent-1328", parent["uuid"])
        Updates::itemAttributeUpdate(item["uuid"], "global-position", Catalyst::newGlobalLastPosition())
    end

    # Catalyst::prependAtBeginingOfChildrenSequence(parent, item)
    def self.prependAtBeginingOfChildrenSequence(parent, item)
        Updates::itemAttributeUpdate(item["uuid"], "parent-1328", parent["uuid"])
        Updates::itemAttributeUpdate(item["uuid"], "global-position", Catalyst::newGlobalFirstPosition())
    end

    # Catalyst::pile3(item)
    def self.pile3(item)
        if item["mikuType"] == "TxCore" then
            NxThreads::pile3(core)
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
                Catalyst::selectSubsetAndMoveToSelectedThread(elements)
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Catalyst::selectSubsetAndMoveToSelectedThread(items)
    def self.selectSubsetAndMoveToSelectedThread(items)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        thread = NxThreads::interactivelySelectOneOrNull()
        return if thread.nil?
        selected.each{|item|
            Updates::itemAttributeUpdate(item["uuid"], "parent-1328", thread["uuid"])
        }
    end

    # Catalyst::redItems()
    def self.redItems()
        Catalyst::mikuType("NxTask")
            .select{|item| item["red-1854"] == CommonUtils::today() }
            .sort_by{|item| item["unixtime"] }
    end

    # Catalyst::maintenance3()
    def self.maintenance3()
        padding = ((Catalyst::mikuType("NxThread") + Catalyst::mikuType("TxCore")).map{|item| item["description"].size } + [0]).max
        XCache::set("b1bd5d84-2051-432a-83d1-62ece0bf54f7", padding)
    end
end
