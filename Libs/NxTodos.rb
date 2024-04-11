
class NxTodos

    # NxTodos::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes2::itemInit(uuid, "NxTodo")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # NxTodos::descriptionToTask1(uuid, description)
    def self.descriptionToTask1(uuid, description)
        Cubes2::itemInit(uuid, "NxTodo")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTodos::icon(item)
    def self.icon(item)
        Catalyst::children(item).empty? ? "🔹" : "🔺"
    end

    # NxTodos::isOrphan(item)
    def self.isOrphan(item)
        item["parentuuid-0032"].nil? or Cubes2::itemOrNull(item["parentuuid-0032"]).nil?
    end

    # NxTodos::listingRatio(item)
    def self.listingRatio(item)
        hours = item["hours"] || 1
        [Bank2::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(hours.to_f/7)
    end

    # NxTodos::performance(item)
    def self.performance(item)
        hours = item["hours"] || 1
        "(#{"%6.2f" % (100 * NxTodos::listingRatio(item))} %; #{"%5.2f" % hours} h/w)".yellow
    end

    # NxTodos::toString(item, context = nil)
    def self.toString(item, context = nil)
        if context == "main-listing-1635" then
            return "#{NxTodos::icon(item)} #{item["description"]}"
        end
        if context == "NxTodos::program2()" then
            return "#{NxTodos::icon(item)} #{NxTodos::performance(item)} #{item["description"]}"
        end
        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxTodos::icon(item)} #{item["description"]}"
    end

    # NxTodos::orphans()
    def self.orphans()
        Cubes2::mikuType("NxTodo")
            .select{|item| NxTodos::isOrphan(item) }
            .sort_by{|item| item["unixtime"] }
    end

    # NxTodos::interactivelySelectOrphanOrNull()
    def self.interactivelySelectOrphanOrNull()
        items = NxTodos::orphans().sort_by{|item| NxTodos::listingRatio(item) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", items, lambda{|item| PolyFunctions::toString(item) })
    end

    # NxTodos::elementsInListingRatioOrder()
    def self.elementsInListingRatioOrder()
        NxTodos::orphans()
            .sort_by{|item| NxTodos::listingRatio(item) }
    end

    # NxTodos::muiItems()
    def self.muiItems()
        NxTodos::elementsInListingRatioOrder()
    end

    # ------------------
    # Ops

    # NxTodos::access(item)
    def self.access(item)
        TxPayload::access(item)
        NxTodos::program1(item)
    end

    # NxTodos::done(item)
    def self.done(item)
        if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", true) then
            Cubes2::destroy(item["uuid"])
        end
    end

    # NxTodos::maintenance()
    def self.maintenance()
        Cubes2::mikuType("NxTodo")
            .select{|item| item["parentuuid-0032"] }
            .select{|item| Cubes2::itemOrNull(item["parentuuid-0032"]).nil? }
            .each{|item|
                Cubes2::setAttribute(item["uuid"], "parentuuid-0032", "c1ec1949-5e0d-44ae-acb2-36429e9146c0") # Misc Timecore
            }
    end

    # NxTodos::program1(todo)
    def self.program1(todo)
        loop {

            todo = Cubes2::itemOrNull(todo["uuid"])
            return if todo.nil?

            system("clear")

            store = ItemStore.new()

            puts ""

            uuids = JSON.parse(XCache::getOrDefaultValue("43ef5eda-d16d-483f-a438-e98d437bedda", "[]"))
            if uuids.size > 0 then
                uuids.each{|uuid|
                    item = Cubes2::itemOrNull(uuid)
                    next if item.nil?
                    puts "[selected] #{PolyFunctions::toString(item)}"
                }
                puts ""
            end

            store.register(todo, false)
            puts MainUserInterface::toString2(store, todo, "inventory")

            puts ""

            Catalyst::children(todo)
                .each{|element|
                    store.register(element, MainUserInterface::canBeDefault(element))
                    puts MainUserInterface::toString2(store, element, "listing-in-todo")
                }

            puts ""

            puts "todo | pile | insert | position * | sort"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                task = NxTodos::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", todo["uuid"])
                position = Catalyst::interactivelySelectPositionInParent(todo)
                Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = Catalyst::interactivelySelectPositionInParent(todo)
                Cubes2::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "pile" then
                Catalyst::interactivelyPileIntoParent(todo)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], Catalyst::children(todo), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", Catalyst::topPositionInParent(todo) - 1)
                }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxTodos::program2()
    def self.program2()
        loop {

            elements = NxTodos::orphans()
                        .sort_by{|item| NxTodos::listingRatio(item) }

            system("clear")

            store = ItemStore.new()

            puts ""

            uuids = JSON.parse(XCache::getOrDefaultValue("43ef5eda-d16d-483f-a438-e98d437bedda", "[]"))
            if uuids.size > 0 then
                uuids.each{|uuid|
                    item = Cubes2::itemOrNull(uuid)
                    next if item.nil?
                    puts "[selected] #{PolyFunctions::toString(item)}"
                }
                puts ""
            end

            weekTotal = elements.map{|item| item["hours"] || 1 }.inject(0, :+)

            puts "> week: #{weekTotal}, day: #{(weekTotal.to_f/7).round(2)}"
            puts ""

            elements
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item, "NxTodos::program2()")
                }

            puts ""
            puts "todo"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                task = NxTodos::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
