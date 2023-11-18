

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
                Catalyst::selectSubsetAndMoveToSelectedCore(elements)
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Catalyst::program3(selector)
    def self.program3(selector)
        loop {

            elements = selector.call()
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
                Catalyst::selectSubsetAndMoveToSelectedCore(elements)
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Catalyst::selectSubsetAndMoveToSelectedCore(items)
    def self.selectSubsetAndMoveToSelectedCore(items)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        core = TxCores::interactivelySelectOneOrNull()
        return if core.nil?
        selected.each{|item|
            Updates::itemAttributeUpdate(item["uuid"], "coreX-2137", core["uuid"])
        }
    end

    # Catalyst::maintenance3()
    def self.maintenance3()
        padding = (Catalyst::mikuType("TxCore").map{|item| item["description"].size } + [0]).max
        XCache::set("b1bd5d84-2051-432a-83d1-62ece0bf54f7", padding)
    end

    # Catalyst::listing_maintenance()
    def self.listing_maintenance()
        if Config::isPrimaryInstance() then
            puts "> Catalyst::listing_maintenance() on primary instance"
            NxTasks::maintenance()
            TxEngines::maintenance0924()
        end
        Catalyst::maintenance3()
    end

    # Catalyst::donationpSuffix(item)
    def self.donationpSuffix(item)
        return "" if item["donation-1605"].nil?
        targets = item["donation-1605"].map{|uuid| Catalyst::itemOrNull(uuid) }.compact
        return "" if targets.empty?
        " (#{targets.map{|target| target["description"]}.join(', ')})".green
    end
end
