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
        "🔺"
    end

    # NxThreads::performance(item)
    def self.performance(item)
        Bank2::recoveredAverageHoursPerDay(item["uuid"])
    end

    # NxThreads::toString(item)
    def self.toString(item)
        "#{NxThreads::icon(item)} #{item["description"]}"
    end

    # NxThreads::itemsInOrder()
    def self.itemsInOrder()
        Cubes2::mikuType("NxThread")
            .sort_by{|item| NxThreads::performance(item) }
    end

    # NxThreads::nonActiveItems()
    def self.nonActiveItems()
        Cubes2::mikuType("NxThread")
            .select{|item| item["hours"].nil? }
            .sort_by{|item| item["unixtime"] }
    end

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", NxThreads::itemsInOrder(), lambda{|item| PolyFunctions::toString(item) })
    end

    # NxThreads::muiItems()
    def self.muiItems()
        Cubes2::mikuType("NxThread")
            .select{|item| Catalyst::isOrphan(item) }
            .select{|item| NxThreads::performance(item) }
    end

    # ------------------
    # Ops

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
            puts MainUserInterface::toString2(store, thread)

            puts ""

            Catalyst::children(thread)
                .each{|element|
                    store.register(element, MainUserInterface::canBeDefault(element))
                    puts MainUserInterface::toString2(store, element)
                }

            puts ""

            puts "todo | pile | insert | position * | sort | selects"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                task = NxThreads::interactivelyIssueNewOrNull()
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

            if input == "pile" then
                Catalyst::interactivelyPileIntoParent(thread)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], Catalyst::children(thread), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", Catalyst::topPositionInParent(thread) - 1)
                }
                next
            end

            if input == "selects" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], Catalyst::children(thread), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Catalyst::addToSelect(i)
                }
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

            NxThreads::itemsInOrder()
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item)
                }

            puts ""
            puts "todo | hours *"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                task = NxThreads::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                next
            end

            if input.start_with?("hours") then
                item = store.get(input[5, 99].strip.to_i)
                next if item.nil?
                hours = NxThreads::interactivelyDecideHoursOrNull()
                Cubes2::setAttribute(item["uuid"], "hours", hours)
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxThreads::maintenance()
    def self.maintenance()
        Cubes2::mikuType("NxThread").each{|thread|
            next if thread["parentuuid-0032"].nil?
            parent = Cubes2::itemOrNull(thread["parentuuid-0032"])
            if parent.nil? then
                Cubes1::setAttribute(thread["uuid"], "parentuuid-0032", nil?)
                next
            end
            if parent["mikuType"] != "TxCore" then
                Cubes1::setAttribute(thread["uuid"], "parentuuid-0032", nil?)
                next
            end
        }

        Cubes2::mikuType("NxThread").each{|thread|
            Catalyst::children(thread).each{|child|
                if child["mikuType"] != "NxTodo" then
                    Cubes1::setAttribute(child["uuid"], "parentuuid-0032", nil?)
                end
            }
        }
    end
end
