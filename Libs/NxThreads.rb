class NxThreads

    # NxThreads::interactivelyDecideHoursOrNull()
    def self.interactivelyDecideHoursOrNull()
        hours = LucilleCore::askQuestionAnswerAsString("hours per week (optional, if you want to activate it): ")
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
        "🧵"
    end

    # NxThreads::ratio(item)
    def self.ratio(item)
        [Bank2::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(item["hours"].to_f/7)
    end

    # NxThreads::ratioString(item)
    def self.ratioString(item)
        return "" if item["hours"].nil?
        " (#{"%6.2f" % (100 * NxThreads::ratio(item))} %; #{"%5.2f" % item["hours"]} h/w)".yellow
    end

    # NxThreads::toString(item)
    def self.toString(item)
        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxThreads::icon(item)} #{item["description"]}#{NxThreads::ratioString(item)}"
    end

    # NxThreads::itemsInOrder()
    def self.itemsInOrder()
        Cubes2::mikuType("NxThread")
            .sort_by{|item| NxThreads::ratio(item) }
    end

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", NxThreads::itemsInOrder(), lambda{|item| PolyFunctions::toString(item) })
    end

    # NxThreads::muiItemsOrphans()
    def self.muiItemsOrphans()
        Cubes2::mikuType("NxThread")
            .select{|item| Catalyst::isOrphan(item) }
            .sort_by{|item| NxThreads::ratio(item) }
    end

    # NxThreads::childrenInOrder(thread)
    def self.childrenInOrder(thread)
        Catalyst::children(thread)
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxThreads::insertionPositions(parent, position, count)
    def self.insertionPositions(parent, position, count)
        children = Catalyst::children(parent)
        if children.empty? then
            return (1..count).to_a
        end
        childrens1 = children.select{|item| (item["global-positioning"] || 0) < position }
        childrens2 = children.select{|item| (item["global-positioning"] || 0) > position }
        if childrens1.empty? and childrens2.empty? then
            # this should not happen
            raise "(error: cb689a8d-5fb9-4b8d-80b7-1f30ecb4edca; parent: #{parent}, position: #{position}, count: #{count})"
        end
        if childrens1.size > 0 and childrens2.size == 0 then
            x = position.ceil
            return (x..x+count-1).to_a
        end
        if childrens1.size == 0 and childrens2.size > 0 then
            x = position.floor - count
            return (x..x+count-1).to_a
        end
        if childrens1.size > 0 and childrens2.size > 0 then
            x1 = childrens1.map{|item| item["global-positioning"] || 0 }.max
            x2 = childrens2.map{|item| item["global-positioning"] || 0 }.min
            spread = 0.8*(x2 - x1)
            shift  = 0.1*(x2 - x1)
            return (0..count-1).to_a.map{|x| x1 + shift + spread*x.to_f/(count) }
        end
    end

    # ------------------
    # Ops

    # NxThreads::interactivelySelectPositionInParent(parent)
    def self.interactivelySelectPositionInParent(parent)
        elements = Catalyst::children(parent)
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
        if position == "" then
            position == rand
        end
        position = position.to_f
        position
    end

    # NxThreads::topPositionInParent(parent)
    def self.topPositionInParent(parent)
        elements = Catalyst::children(parent)
        ([0] + elements.map{|item| item["global-positioning"] || 0 }).min
    end

    # NxThreads::interactivelyInsertAtPosition(parent, position)
    def self.interactivelyInsertAtPosition(parent, position)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        descriptions = text.lines.map{|line| line.strip }.select{|line| line != "" }
        positions = NxThreads::insertionPositions(parent, position, descriptions.size)
        descriptions.zip(positions).each{|description, position|
            task = NxTodos::descriptionToTask1(parent, SecureRandom.hex, description)
            puts JSON.pretty_generate(task)
            Cubes2::setAttribute(task["uuid"], "global-positioning", position)
        }
    end

    # NxThreads::interactivelyPile(thread)
    def self.interactivelyPile(thread)
        position = NxThreads::topPositionInParent(thread) - 1
        NxThreads::interactivelyInsertAtPosition(thread, position)
    end

    # NxThreads::program1(thread)
    def self.program1(thread)
        loop {

            thread = Cubes2::itemOrNull(thread["uuid"])
            return if thread.nil?

            system("clear")

            store = ItemStore.new()

            puts ""

            store.register(thread, false)
            puts Listing::toString2(store, thread)

            puts ""

            NxThreads::childrenInOrder(thread)
                .each{|element|
                    store.register(element, Listing::canBeDefault(element))
                    puts Listing::toString2(store, element)
                }

            puts ""

            puts "todo | thread | pile | insert | position * | sort | moves"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                todo = NxTodos::interactivelyIssueNewOrNull()
                next if todo.nil?
                puts JSON.pretty_generate(todo)
                Cubes2::setAttribute(todo["uuid"], "parentuuid-0032", thread["uuid"])
                position = NxThreads::interactivelySelectPositionInParent(thread)
                Cubes2::setAttribute(todo["uuid"], "global-positioning", position)
                next
            end

            if input == "thread" then
                t2 = NxThreads::interactivelyIssueNewOrNull()
                next if t2.nil?
                puts JSON.pretty_generate(t2)
                Cubes2::setAttribute(t2["uuid"], "parentuuid-0032", thread["uuid"])
                position = NxThreads::interactivelySelectPositionInParent(thread)
                Cubes2::setAttribute(t2["uuid"], "global-positioning", position)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = NxThreads::interactivelySelectPositionInParent(thread)
                Cubes2::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "pile" then
                NxThreads::interactivelyPile(thread)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], NxThreads::childrenInOrder(thread), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxThreads::topPositionInParent(thread) - 1)
                }
                next
            end

            if input == "moves" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], NxThreads::childrenInOrder(thread), lambda{|i| PolyFunctions::toString(i) })
                next if selected.empty?
                t2 = NxThreads::interactivelySelectOneOrNull()
                next if t2.nil?
                selected.each{|i| Cubes2::setAttribute(i["uuid"], "parentuuid-0032", t2["uuid"]) }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
