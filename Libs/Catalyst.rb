

class Catalyst

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Cubes::setAttribute(item["uuid"], key, value)
        }
    end

    # Catalyst::program2(elements)
    def self.program2(elements)
        loop {

            elements = elements.map{|item| Cubes::itemOrNull(item["uuid"]) }.compact
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
            Cubes::setAttribute(item["uuid"], "coreX-2137", core["uuid"])
        }
    end

    # Catalyst::maintenance3()
    def self.maintenance3()
        padding = (Cubes::mikuType("TxCore").map{|item| item["description"].size } + [0]).max
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

    # Catalyst::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["donation-1605"].nil?
        targets = item["donation-1605"].map{|uuid| Cubes::itemOrNull(uuid) }.compact
        return "" if targets.empty?
        " (#{targets.map{|target| target["description"]}.join(', ')})".green
    end
end
