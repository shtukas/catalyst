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
        item["hours"] ? "🔺" : "🔸"
    end

    # NxThreads::listingRatio(item)
    def self.listingRatio(item)
        raise "(error: cbf9ee6d-8c02) item does not have hours: #{item}" if item["hours"].nil?
        [Bank2::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(item["hours"].to_f/7)
    end

    # NxThreads::ratioString(item)
    def self.ratioString(item)
        raise "(error: 411e613e-6d12) item does not have hours: #{item}" if item["hours"].nil?
        "(#{"%6.2f" % (100 * NxThreads::listingRatio(item))} %; #{"%5.2f" % item["hours"]} h/w)".yellow
    end

    # NxThreads::toString(item, context = nil)
    def self.toString(item, context = nil)
        if item["hours"] then
            "#{NxThreads::icon(item)} #{NxThreads::ratioString(item)} #{item["description"]}"
        else
            "#{NxThreads::icon(item)} #{item["description"]}"
        end
    end

    # NxThreads::activeItems()
    def self.activeItems()
        Cubes2::mikuType("NxThread")
            .select{|item| item["hours"] }
            .sort_by{|item| NxThreads::listingRatio(item) }
    end

    # NxThreads::nonActiveItems()
    def self.nonActiveItems()
        Cubes2::mikuType("NxThread")
            .select{|item| item["hours"].nil? }
            .sort_by{|item| item["unixtime"] }
    end

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxThreads::activeItems() + NxThreads::nonActiveItems()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", items, lambda{|item| PolyFunctions::toString(item) })
    end

    # NxThreads::muiItems1()
    def self.muiItems1()
        NxThreads::activeItems()
            .select{|item| NxThreads::listingRatio(item) < 1 }
    end

    # NxThreads::muiItems2()
    def self.muiItems2()
        NxThreads::nonActiveItems()
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
            puts MainUserInterface::toString2(store, thread, "inventory")

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

            elements = NxThreads::activeItems() + NxThreads::nonActiveItems()

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
                    puts MainUserInterface::toString2(store, item, "icon+performance+description")
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

    # NxThreads::interactivelySetParent(item)
    def self.interactivelySetParent(item)
        parent = NxThreads::interactivelySelectOneOrNull()
        return if parent.nil?
        Cubes2::setAttribute(item["uuid"], "parentuuid-0032", parent["uuid"])
        position = Catalyst::interactivelySelectPositionInParent(parent)
        Cubes2::setAttribute(item["uuid"], "global-positioning", position)
    end

    # NxThreads::interactivelySetDonation(item)
    def self.interactivelySetDonation(item)
        puts "Set donation for item: '#{PolyFunctions::toString(item)}'"
        target = NxThreads::interactivelySelectOneOrNull()
        return if target.nil?
        Cubes2::setAttribute(item["uuid"], "donation-1601", target["uuid"])
    end
end
