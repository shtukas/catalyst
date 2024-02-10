

class Catalyst

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Cubes2::setAttribute(item["uuid"], key, value)
        }
    end

    # Catalyst::program2(elements, context = nil, prefixLambda = nil)
    def self.program2(elements, context = nil, prefixLambda = nil)
        loop {

            elements = elements.map{|item| Cubes2::itemOrNull(item["uuid"]) }.compact
            return if elements.empty?

            system("clear")

            if prefixLambda then
                puts ""
                puts prefixLambda.call()
            end

            store = ItemStore.new()

            puts ""

            elements
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item, context)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Catalyst::periodicPrimaryInstanceMaintenance()
    def self.periodicPrimaryInstanceMaintenance()
        if Config::isPrimaryInstance() then
            puts "> Catalyst::periodicPrimaryInstanceMaintenance()"
            Cubes1::maintenance()
            DoNotShowUntil1::maintenance()
            NxBackups::maintenance()
            NxTodos::maintenance()
            if Cubes2::mikuType("NxTodo").size < 100 then
                Cubes2::mikuType("NxIce").take(10).each{|item|

                }
            end
        end
    end

    # Catalyst::donationSuffix(item)
    def self.donationSuffix(item)
        return "" if item["donation-1752"].nil?
        " (#{item["donation-1752"].map{|uuid| Cubes2::itemOrNull(uuid)}.compact.map{|target| target["description"]}.join(", ")})".green
    end

    # Catalyst::selectTodoTextFileLocationOrNull(todotextfile)
    def self.selectTodoTextFileLocationOrNull(todotextfile)
        location = XCache::getOrNull("fcf91da7-0600-41aa-817a-7af95cd2570b:#{todotextfile}")
        if location and File.exist?(location) then
            return location
        end

        roots = [Config::pathToGalaxy()]
        Galaxy::locationEnumerator(roots).each{|location|
            if File.basename(location).include?(todotextfile) then
                XCache::set("fcf91da7-0600-41aa-817a-7af95cd2570b:#{todotextfile}", location)
                return location
            end
        }
        nil
    end

    # Catalyst::addDonation(item, target)
    def self.addDonation(item, target)
        donation = ((item["donation-1752"] || []) + [target["uuid"]]).uniq
        Cubes2::setAttribute(item["uuid"], "donation-1752", donation)
    end

    # Catalyst::interactivelySetDonations(item)
    def self.interactivelySetDonations(item)
        target = Catalyst::interactivelySelectContainerDescentFromRootOrNull()
        if target then
            Catalyst::addDonation(item, target)
        end
    end

    # Catalyst::interactivelySelectContainerDescentFromRootOrNull(cursor = nil)
    def self.interactivelySelectContainerDescentFromRootOrNull(cursor = nil)
        selectOrDive = lambda{|item|
            puts PolyFunctions::toString(item).green
            options = ["select (default)", "dive"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            if option.nil?  or option == "select (default)" then
                return "select"
            end
            "dive"
        }

        if cursor.nil? then
            orbital = NxOrbitals::interactivelySelectOneOrNull()
            return nil if orbital.nil?
            if selectOrDive.call(orbital) == "select" then
                return orbital
            else
                return Catalyst::interactivelySelectContainerDescentFromRootOrNull(orbital)
            end
        end
        if cursor["mikuType"] == "NxOrbital" or cursor["mikuType"] == "NxBlock" then
            createBlockAtContainer = lambda{|container|
                block = NxBlocks::interactivelyIssueNewOrNull()
                return if block.nil?
                puts JSON.pretty_generate(block)
                Cubes2::setAttribute(block["uuid"], "parentuuid-0032", container["uuid"])
                position = Catalyst::interactivelySelectPositionInContainerOrNull(container)
                Cubes2::setAttribute(block["uuid"], "global-positioning", position)
            }

            puts ""
            store = ItemStore.new()
            store.register(cursor, false)
            puts MainUserInterface::toString2(store, cursor).green
            Catalyst::childrenThatAreBlocks(cursor)
                .each{|block|
                    store.register(block, false)
                    puts MainUserInterface::toString2(store, block)
                }
            puts "new (here)"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            if input == "" then
                return Catalyst::interactivelySelectContainerDescentFromRootOrNull(cursor)
            end
            if input == "new" then
                createBlockAtContainer.call(cursor)
                return Catalyst::interactivelySelectContainerDescentFromRootOrNull(cursor)
            end
            if input == "0" then
                return cursor
            end
            target = store.get(input.to_i)
            if target.nil? then
                return Catalyst::interactivelySelectContainerDescentFromRootOrNull(cursor)
            end
            if selectOrDive.call(target) == "select" then
                return target
            else
                return Catalyst::interactivelySelectContainerDescentFromRootOrNull(target)
            end
        end
        raise "(error: d7256dcc-6d95-42b4-9fd2-3f1e5c2b674b) cursor: #{cursor}"
    end

    # Catalyst::children(listing)
    def self.children(listing)
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == listing["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # Catalyst::childrenThatAreBlocks(timecore)
    def self.childrenThatAreBlocks(timecore)
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == timecore["uuid"] }
            .select{|item| item["mikuType"] == "NxBlock" }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # Catalyst::interactivelySelectPositionInContainerOrNull(container)
    def self.interactivelySelectPositionInContainerOrNull(container)
        elements = Catalyst::children(container)
        elements.first(20).each{|item|
            puts "#{PolyFunctions::toString(item)}"
        }
        position = LucilleCore::askQuestionAnswerAsString("position (first, next, <position>): ")
        if position == "first" then
            return ([0] + elements.map{|item| item["global-positioning"] || 0 }).min - 1
        end
        if position == "next" then
            return ([0] + elements.map{|item| item["global-positioning"] || 0 }).max + 1
        end
        position = position.to_f
        position
    end

    # Catalyst::selectSubsetOfItemsAndMoveToSelectedContainer(items)
    def self.selectSubsetOfItemsAndMoveToSelectedContainer(items)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        node = Catalyst::interactivelySelectContainerDescentFromRootOrNull()
        return if node.nil?
        selected.each{|item|
            Cubes2::setAttribute(item["uuid"], "parentuuid-0032", node["uuid"])
        }
        if selected.size == 1 then
            selected = selected.first
            position = Catalyst::interactivelySelectPositionInContainerOrNull(node)
            if position then
                Cubes2::setAttribute(selected["uuid"], "global-positioning", position)
            end
        end
    end
end
