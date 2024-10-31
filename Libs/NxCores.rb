
class NxCores

    # NxCores::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull(uuid)
        hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        Items::itemInit(uuid, "NxCore")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "hours", hours)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxCores::ratio(item)
    def self.ratio(item)
        hours = item["hours"].to_f
        [Bank1::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(hours/7)
    end

    # NxCores::ratioString(item)
    def self.ratioString(item)
        "(#{"%6.2f" % (100 * NxCores::ratio(item))} %; #{"%5.2f" % item["hours"]} h/w)".yellow
    end

    # NxCores::toString(item)
    def self.toString(item)
        "⏱️  #{NxCores::ratioString(item)} #{item["description"]}"
    end

    # NxCores::itemsInRatioOrder()
    def self.itemsInRatioOrder()
        Items::mikuType("NxCore").sort_by{|item| NxCores::ratio(item) }
    end

    # NxCores::listingItems()
    def self.listingItems()
        Items::mikuType("NxCore")
            .select{|item| Listing::listable(item) }
            .select{|item| NxCores::ratio(item) < 1 }
            .sort_by{|item| NxCores::ratio(item) }
    end

    # NxCores::interactivelySelectOrNull()
    def self.interactivelySelectOrNull()
        items = Items::mikuType("NxCore")
                    .sort_by{|item| NxCores::ratio(item) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", items, lambda{|item| PolyFunctions::toString(item) })
    end

    # ------------------
    # Ops

    # NxCores::program1(core)
    def self.program1(core)
        loop {

            core = Items::itemOrNull(core["uuid"])
            return if core.nil?

            system("clear")

            store = ItemStore.new()

            puts ""

            store.register(core, false)
            puts Listing::toString2(store, core)

            puts ""

            children = Catalyst::childrenInGlobalPositioningOrder(core)
                .each{|element|
                    store.register(element, Listing::canBeDefault(element))
                    puts Listing::toString2(store, element)
                }

            puts ""

            puts "todo (here, with position selection) | pile | position * | sort"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                todo = NxTasks::interactivelyIssueNewOrNull()
                next if todo.nil?
                puts JSON.pretty_generate(todo)
                Items::setAttribute(todo["uuid"], "parentuuid-0014", core["uuid"])
                position = Catalyst::interactivelySelectPositionInParent(core)
                Items::setAttribute(todo["uuid"], "global-positioning", position)
                next
            end

            if input == "pile" then
                todo = NxTasks::interactivelyIssueNewOrNull()
                next if todo.nil?
                puts JSON.pretty_generate(todo)
                Items::setAttribute(todo["uuid"], "parentuuid-0014", core["uuid"])
                position = Catalyst::firstPositionInParent(core) - 1
                Items::setAttribute(todo["uuid"], "global-positioning", position)
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = Catalyst::interactivelySelectPositionInParent(core)
                Items::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], Catalyst::childrenInGlobalPositioningOrder(core), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Items::setAttribute(i["uuid"], "global-positioning", Catalyst::firstPositionInParent(core) - 1)
                }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxCores::program2()
    def self.program2()
        loop {
 
            system("clear")
 
            store = ItemStore.new()
 
            puts ""

            NxCores::itemsInRatioOrder()
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts Listing::toString2(store, item)
                }
 
            puts ""
            puts "core | hours *"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""
 
            if input == "core" then
                core = NxCores::interactivelyIssueNewOrNull()
                next if core.nil?
                puts JSON.pretty_generate(core)
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
