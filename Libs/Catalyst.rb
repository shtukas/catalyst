

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

    # Catalyst::gloalFirstPosition()
    def self.gloalFirstPosition()
        Catalyst::catalystItems()
            .select{|item| item["global-position"] }
            .map{|item| item["global-position"] }
            .reduce(0){|number, x| [number, x].min}
    end

    # Catalyst::globalLastPosition()
    def self.globalLastPosition()
        Catalyst::catalystItems()
            .select{|item| item["global-position"] }
            .map{|item| item["global-position"] }
            .reduce(0){|number, x| [number, x].max}
    end

    # Catalyst::prependAtBeginingOfChildrenSequence(parent, item)
    def self.prependAtBeginingOfChildrenSequence(parent, item)
        Updates::itemAttributeUpdate(item["uuid"], "parent-1328", parent["uuid"])
        Updates::itemAttributeUpdate(item["uuid"], "global-position", Catalyst::gloalFirstPosition()-1)
    end

    # Catalyst::pile3(item)
    def self.pile3(item)
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
        thread = NxThreads::interactivelySelectOneOrNullUsingTopDownNavigation(nil)
        return if thread.nil?
        selected.each{|item|
            Updates::itemAttributeUpdate(item["uuid"], "parent-1328", thread["uuid"])
        }
    end

    # Catalyst::maintenance2()
    def self.maintenance2()
        t = Catalyst::gloalFirstPosition()
        if t < 0 then
            Catalyst::catalystItems()
                .each{|item|
                    Updates::itemAttributeUpdate(item["uuid"], "global-position", (item["global-position"] || 0) + (-t))
                }
        end
        t = Catalyst::globalLastPosition()
        if t >= 1000 then
            Catalyst::catalystItems()
                .each{|item|
                    Updates::itemAttributeUpdate(item["uuid"], "global-position", 0.9*(item["global-position"] || 0))
                }
        end
    end

    # Catalyst::maintenance3()
    def self.maintenance3()
        padding = (Catalyst::mikuType("NxThread").map{|item| item["description"].size } + [0]).max
        XCache::set("b1bd5d84-2051-432a-83d1-62ece0bf54f7", padding)
    end

    # Catalyst::listing_maintenance()
    def self.listing_maintenance()
        if Config::isPrimaryInstance() then
            puts "> Catalyst::listing_maintenance() on primary instance"
            NxTasks::maintenance()
            OpenCycles::maintenance()
            TxEngines::maintenance0924()
            OpenCycles::maintenance()
            Catalyst::maintenance2()

            Catalyst::catalystItems().each{|item|
                next if item["parent-1328"].nil?
                parent = Catalyst::itemOrNull(item["parent-1328"])
                if parent.nil? then
                    Updates::itemAttributeUpdate(item["uuid"], "parent-1328", nil)
                end
            }
        end
        Catalyst::maintenance3()
    end

    # Catalyst::donationpSuffix(item)
    def self.donationpSuffix(item)
        return "" if item["donation-1605"].nil?
        target = Catalyst::itemOrNull(item["donation-1605"])
        return "" if target.nil?
        " (#{target["description"]})".green
    end
end
