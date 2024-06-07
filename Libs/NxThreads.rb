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
        Items::itemInit(uuid, "NxThread")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "hours", hours)
        Items::itemOrNull(uuid)
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

    # NxThreads::itemsInCompletionOrder()
    def self.itemsInCompletionOrder()
        Items::mikuType("NxThread")
            .sort_by{|item| NxThreads::ratio(item) }
    end

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", NxThreads::itemsInCompletionOrder(), lambda{|item| PolyFunctions::toString(item) })
    end

    # NxThreads::muiItems()
    def self.muiItems()
        Items::mikuType("NxThread")
            .select{|thread|
                if thread["do-not-show-if-empty"] then
                    Catalyst::children(thread).size > 0
                else
                    true
                end
            }
            .select{|item| NxThreads::ratio(item) < 1 }
            .sort_by{|item| NxThreads::ratio(item) }
    end

    # ------------------
    # Ops

    # NxThreads::program1(thread)
    def self.program1(thread)
        loop {

            thread = Items::itemOrNull(thread["uuid"])
            return if thread.nil?

            system("clear")

            store = ItemStore.new()

            puts ""

            store.register(thread, false)
            puts Listing::toString2(store, thread)

            puts ""

            Catalyst::childrenInGlobalPositioningOrder(thread)
                .each{|element|
                    store.register(element, Listing::canBeDefault(element))
                    puts Listing::toString2(store, element)
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
                Items::setAttribute(todo["uuid"], "parentuuid-0032", thread["uuid"])
                position = Catalyst::interactivelySelectPositionInParent(thread)
                Items::setAttribute(todo["uuid"], "global-positioning", position)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = Catalyst::interactivelySelectPositionInParent(thread)
                Items::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "pile" then
                Catalyst::interactivelyPile(thread)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], Catalyst::childrenInGlobalPositioningOrder(thread), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Items::setAttribute(i["uuid"], "global-positioning", Catalyst::topPositionInParent(thread) - 1)
                }
                next
            end

            if input == "moves" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], Catalyst::childrenInGlobalPositioningOrder(thread), lambda{|i| PolyFunctions::toString(i) })
                next if selected.empty?
                t2 = NxThreads::interactivelySelectOneOrNull()
                next if t2.nil?
                selected.each{|i| Items::setAttribute(i["uuid"], "parentuuid-0032", t2["uuid"]) }
                next
            end

            if input == "do not show if empty" then
                Items::setAttribute(thread["uuid"], "do-not-show-if-empty", true)
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

            NxThreads::itemsInCompletionOrder()
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts Listing::toString2(store, item)
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
                Items::setAttribute(item["uuid"], "hours", hours)
                next
            end
 
            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
