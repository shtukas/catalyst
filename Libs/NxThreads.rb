
class NxThreads

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        hours = (hours == 0) ? 1 : hours
        Cubes2::itemInit(uuid, "NxThread")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "hours", hours)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxThreads::icon(item)
    def self.icon(item)
        "🔸"
    end

    # NxThreads::performance(item)
    def self.performance(item)
        hours = item["hours"] || 1
        "(#{"%6.2f" % (100 * NxThreads::listingRatio(item))} %; #{"%5.2f" % hours} h/w)".yellow
    end

    # NxThreads::toString(item, context = nil)
    def self.toString(item, context = nil)
        "#{NxThreads::icon(item)} #{NxThreads::performance(item)} #{item["description"]}"
    end

    # NxThreads::itemsInGlobalPositioningOrder()
    def self.itemsInGlobalPositioningOrder()
        Cubes2::mikuType("NxThread").sort_by{|project| project["global-positioning"] || 0 }
    end

    # NxThreads::topPositionAmongThreads()
    def self.topPositionAmongThreads()
        ([0] + Cubes2::mikuType("NxThread").map{|task| task["global-positioning"] || 0 }).min
    end

    # NxThreads::topPositionAmongChildren(item)
    def self.topPositionAmongChildren(item)
        ([0] + Catalyst::children(item).map{|task| task["global-positioning"] || 0 }).min
    end

    # NxThreads::topPosition()
    def self.topPosition()
        ([0] + Cubes2::mikuType("NxThread").map{|project| project["global-positioning"] || 0 }).min
    end

    # NxThreads::nextPosition()
    def self.nextPosition()
        ([0] + Cubes2::mikuType("NxThread").map{|project| project["global-positioning"] || 0 }).max + 1
    end

    # NxThreads::basicHoursPerDayForProjectsWithoutEngine()
    def self.basicHoursPerDayForProjectsWithoutEngine()
        1.5
    end

    # NxThreads::itemsInGlobalPositioningOrder()
    def self.itemsInGlobalPositioningOrder()
        Cubes2::mikuType("NxThread")
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxThreads::threadsAndTodosInGlobalPositioningOrder()
    def self.threadsAndTodosInGlobalPositioningOrder()
        (Cubes2::mikuType("NxThread") + NxTodos::orphans())
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxThreads::threadsAndTodosInListingRatioOrder()
    def self.threadsAndTodosInListingRatioOrder()
        (Cubes2::mikuType("NxThread") + NxTodos::orphans())
            .sort_by{|item| NxThreads::listingRatio(item) }
    end

    # NxThreads::listingRatio(item)
    def self.listingRatio(item)
        if item["mikuType"] == "NxThread" then
            hours = item["hours"] || 1
            return Bank2::recoveredAverageHoursPerDay(item["uuid"]).to_f/(hours.to_f/7)
        end
        if item["mikuType"] == "NxTodo" then
            return Bank2::recoveredAverageHoursPerDay(item["uuid"]).to_f/(1.to_f/7)
        end
        raise "(error: eb612cb5-61c0-40bf-8b8f-7972e3923ad0): item: #{item}"
    end

    # NxThreads::muiItems()
    def self.muiItems()
        NxThreads::threadsAndTodosInListingRatioOrder()
    end

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", NxThreads::threadsAndTodosInListingRatioOrder(), lambda{|item| PolyFunctions::toString(item) })
    end

    # ------------------
    # Ops

    # NxThreads::access(item)
    def self.access(item)
        NxThreads::program1(item)
    end

    # NxThreads::access(item)
    def self.natural(item)
        NxThreads::access(item)
    end

    # NxThreads::program1(thread)
    def self.program1(thread)
        loop {

            thread = Cubes2::itemOrNull(thread["uuid"])
            return if thread.nil?

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

            store.register(thread, false)
            puts MainUserInterface::toString2(store, thread, "inventory")

            puts ""

            Catalyst::children(thread)
                .each{|element|
                    store.register(element, MainUserInterface::canBeDefault(element))
                    puts MainUserInterface::toString2(store, element, "listing-in-thread")
                }

            puts ""

            puts "todo | position * | sort"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                task = NxTodos::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", thread["uuid"])
                position = Catalyst::interactivelySelectPositionInParent(thread)
                Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = Catalyst::interactivelySelectPositionInParent(thread)
                Cubes2::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], Catalyst::children(thread), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxThreads::topPositionAmongChildren(thread) - 1)
                }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxThreads::program2()
    def self.program2()
        loop {

            elements = (Cubes2::mikuType("NxThread") + NxTodos::orphans())
                        .sort_by{|item| NxThreads::listingRatio(item) }

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
                    puts MainUserInterface::toString2(store, item, "NxThreads::program2()")
                }

            puts ""

            Cubes2::mikuType("TxCore")
                .sort_by{|item| TxCores::ratio(item) }
                .each{|item|
                    store.register(item, false)
                    puts MainUserInterface::toString2(store, item)
                }

            puts ""
            puts "todo | thread | sort"
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

            if input == "thread" then
                NxThreads::interactivelyIssueNewOrNull()
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], elements, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxThreads::topPositionAmongThreads() - 1)
                }
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxThreads::maintenance()
    def self.maintenance()
        Cubes2::mikuType("NxThread")
            .select{|item| item["parentuuid-0032"] }
            .select{|item| Cubes2::itemOrNull(item["parentuuid-0032"]).nil? }
            .each{|item|
                Cubes2::setAttribute(item["uuid"], "parentuuid-0032", "c1ec1949-5e0d-44ae-acb2-36429e9146c0") # Misc Timecore
            }
    end

    # NxThreads::interactivelyInsertIntoThread(todo)
    def self.interactivelyInsertIntoThread(todo)
        thread = NxThreads::interactivelySelectOneOrNull()
        return if thread.nil?
        position = Catalyst::interactivelySelectPositionInParent(thread)
        Cubes2::setAttribute(todo["uuid"], "global-positioning", position)
    end
end
