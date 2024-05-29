class NxThreads

    # NxThreads::interactivelyDecideHoursOrNull()
    def self.interactivelyDecideHoursOrNull()
        hours = LucilleCore::askQuestionAnswerAsString("hours per week (optional): ")
        if hours == "" then
            hours = nil
        else
            hours = hours.to_f
            if hours == 0 then
                hours = nil
            end
        end
        hours
    end

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        hours = NxThreads::interactivelyDecideHoursOrNull()
        Cubes1::itemInit(uuid, "NxThread")
        Cubes1::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes1::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes1::setAttribute(uuid, "description", description)
        Cubes1::setAttribute(uuid, "hours", hours)
        Cubes1::itemOrNull(nil, uuid)
    end

    # ------------------
    # Data

    # NxThreads::icon(item)
    def self.icon(item)
        "🪔"
    end

    # NxThreads::ratio(item)
    def self.ratio(item)
        if item["hours"].nil? then
            item["hours"] = 1
        end
        [Bank1::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(item["hours"].to_f/7)
    end

    # NxThreads::ratioString(item)
    def self.ratioString(item)
        return "" if item["hours"].nil?
        " (#{"%6.2f" % (100 * NxThreads::ratio(item))} %; #{"%5.2f" % item["hours"]} h/w)".yellow
    end

    # NxThreads::toString(item)
    def self.toString(item)
        "#{NxThreads::icon(item)} #{item["description"]}#{NxThreads::ratioString(item)}"
    end

    # NxThreads::itemsInCompletionOrder(datatrace)
    def self.itemsInCompletionOrder(datatrace)
        Cubes1::mikuType(datatrace, "NxThread")
            .sort_by{|item| NxThreads::ratio(item) }
    end

    # NxThreads::interactivelySelectOneOrNull(datatrace)
    def self.interactivelySelectOneOrNull(datatrace)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", NxThreads::itemsInCompletionOrder(datatrace), lambda{|item| PolyFunctions::toString(item) })
    end

    # NxThreads::muiItems(datatrace)
    def self.muiItems(datatrace)
        Cubes1::mikuType(datatrace, "NxThread")
            .select{|thread|
                if thread["do-not-show-if-empty"] then
                    Catalyst::children(datatrace, thread).size > 0
                else
                    true
                end
            }
            .sort_by{|item| NxThreads::ratio(item) }
    end

    # ------------------
    # Ops

    # NxThreads::program1(thread)
    def self.program1(thread)
        loop {

            thread = Cubes1::itemOrNull(nil, thread["uuid"])
            return if thread.nil?

            system("clear")

            store = ItemStore.new()

            puts ""

            store.register(thread, false)
            puts Listing::toString2(Catalyst::datatrace(), store, thread)

            puts ""

            datatrace = Catalyst::datatrace()

            Catalyst::childrenInGlobalPositioningOrder(datatrace, thread)
                .each{|element|
                    store.register(element, Listing::canBeDefault(element))
                    puts Listing::toString2(datatrace, store, element)
                }

            puts ""

            puts "todo | pile | insert | position * | sort | moves | do not show if empty"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                todo = NxTodos::interactivelyIssueNewOrNull()
                next if todo.nil?
                puts JSON.pretty_generate(todo)
                Cubes1::setAttribute(todo["uuid"], "parentuuid-0032", thread["uuid"])
                position = Catalyst::interactivelySelectPositionInParent(Catalyst::datatrace(), thread)
                Cubes1::setAttribute(todo["uuid"], "global-positioning", position)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = Catalyst::interactivelySelectPositionInParent(Catalyst::datatrace(), thread)
                Cubes1::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "pile" then
                Catalyst::interactivelyPile(Catalyst::datatrace(), thread)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], Catalyst::childrenInGlobalPositioningOrder(Catalyst::datatrace(), thread), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes1::setAttribute(i["uuid"], "global-positioning", Catalyst::topPositionInParent(Catalyst::datatrace(), thread) - 1)
                }
                next
            end

            if input == "moves" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], Catalyst::childrenInGlobalPositioningOrder(Catalyst::datatrace(), thread), lambda{|i| PolyFunctions::toString(i) })
                next if selected.empty?
                datatrace = Catalyst::datatrace()
                t2 = NxThreads::interactivelySelectOneOrNull(datatrace)
                next if t2.nil?
                selected.each{|i| Cubes1::setAttribute(i["uuid"], "parentuuid-0032", t2["uuid"]) }
                next
            end

            if input == "do not show if empty" then
                Cubes1::setAttribute(thread["uuid"], "do-not-show-if-empty", true)
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxThreads::program2()
    def self.program2()
        loop {
 
            system("clear")
 
            store = ItemStore.new()
 
            puts ""

            datatrace = Catalyst::datatrace()
            NxThreads::itemsInCompletionOrder(datatrace)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts Listing::toString2(datatrace, store, item)
                }
 
            puts ""
            puts "thread | hours *"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""
 
            if input == "thread" then
                thread = NxThreads::interactivelyIssueNewOrNull()
                next if thread.nil?
                puts JSON.pretty_generate(thread)
                next
            end
 
            if input.start_with?("hours") then
                item = store.get(input[5, 99].strip.to_i)
                next if item.nil?
                hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
                Cubes1::setAttribute(item["uuid"], "hours", hours)
                next
            end
 
            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
