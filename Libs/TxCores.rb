class TxCores

    # TxCores::interactivelyDecideHoursOrNull()
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

    # TxCores::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        hours = TxCores::interactivelyDecideHoursOrNull()
        Items::itemInit(uuid, "TxCore")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "hours-1905", hours)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # TxCores::icon(item)
    def self.icon(item)
        "⏱️ "
    end

    # TxCores::ratio(item)
    def self.ratio(item)
        if item["hours-1905"].nil? then
            item["hours-1905"] = 1
        end
        [Bank1::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(item["hours-1905"].to_f/7)
    end

    # TxCores::ratioString(item)
    def self.ratioString(item)
        return "" if item["hours-1905"].nil?
        " (#{"%6.2f" % (100 * TxCores::ratio(item))} %; #{"%5.2f" % item["hours-1905"]} h/w)".yellow
    end

    # TxCores::toString(item)
    def self.toString(item)
        "#{TxCores::icon(item)} #{item["description"]}#{TxCores::ratioString(item)}"
    end

    # TxCores::itemsInCompletionOrder()
    def self.itemsInCompletionOrder()
        Items::mikuType("TxCore")
            .sort_by{|item| TxCores::ratio(item) }
    end

    # TxCores::listingItems()
    def self.listingItems()
        Items::mikuType("TxCore")
            .select{|item| TxCores::ratio(item) < 1 }
            .sort_by{|item| TxCores::ratio(item) }
    end

    # TxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", TxCores::itemsInCompletionOrder(), lambda{|item| PolyFunctions::toString(item) })
    end

    # TxCores::childrenForPrefix(core)
    def self.childrenForPrefix(core)
        children = Catalyst::children(core)
        c1, c2 = children.partition{|item| item["mikuType"] == "NxCollection" }
        [
            c1.sort_by{|item| NxCollections::ratio(item) }.select{|item| NxCollections::ratio(item) < 1 },
            c2.sort_by{|i| (i["global-positioning"] || 0) }
        ].flatten
    end

    # TxCores::infinityuuid()
    def self.infinityuuid()
        "85e2e9fe-ef3d-4f75-9330-2804c4bcd52b"
    end

    # TxCores::childrenForInfinityPrefix()
    def self.childrenForInfinityPrefix()
        bufferIn = NxBufferInItems::items()
                    .sort_by{|item| item["location"] }
        return bufferIn if bufferIn.size > 0

        orphans = NxTasks::orphans()
                    .sort_by{|item| item["unixtime"] }
        return orphans if orphans.size > 0
        TxCores::childrenForPrefix(Items::itemOrNull(TxCores::infinityuuid())) # infinity
    end

    # ------------------
    # Ops

    # TxCores::program1(core)
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
                .first(40)
                .each{|element|
                    store.register(element, Listing::canBeDefault(element))
                    puts Listing::toString2(store, element, "thread-elements-listing")
                }

            puts ""

            puts "task | thread | pile | position * | sort | move * | moves"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                todo = NxTasks::interactivelyIssueNewOrNull()
                next if todo.nil?
                puts JSON.pretty_generate(todo)
                Items::setAttribute(todo["uuid"], "parentuuid-0032", core["uuid"])
                position = Catalyst::interactivelySelectPositionInParent(core)
                Items::setAttribute(todo["uuid"], "global-positioning", position)
                next
            end

            if input == "thread" then
                tx1 = NxCollections::interactivelyIssueNewOrNull()
                next if tx1.nil?
                puts JSON.pretty_generate(tx1)
                Items::setAttribute(tx1["uuid"], "parentuuid-0032", tx1["uuid"])
                position = Catalyst::interactivelySelectPositionInParent(tx1)
                Items::setAttribute(tx1["uuid"], "global-positioning", position)
                next
            end

            if input.start_with?("move") then
                listord = input[4, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                t2 = Catalyst::interactivelySelectOneHierarchyParentOrNull(nil)
                next if t2.nil?
                Items::setAttribute(i["uuid"], "parentuuid-0032", t2["uuid"])
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

            if input == "pile" then
                Catalyst::interactivelyPile(core)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], Catalyst::childrenInGlobalPositioningOrder(core), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Items::setAttribute(i["uuid"], "global-positioning", Catalyst::topPositionInParent(core) - 1)
                }
                next
            end

            if input == "moves" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], Catalyst::childrenInGlobalPositioningOrder(core), lambda{|i| PolyFunctions::toString(i) })
                next if selected.empty?
                t2 = Catalyst::interactivelySelectOneHierarchyParentOrNull(nil)
                next if t2.nil?
                selected.each{|i| Items::setAttribute(i["uuid"], "parentuuid-0032", t2["uuid"]) }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # TxCores::program2()
    def self.program2()
        loop {
 
            system("clear")
 
            store = ItemStore.new()
 
            puts ""

            TxCores::itemsInCompletionOrder()
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
                core = TxCores::interactivelyIssueNewOrNull()
                next if core.nil?
                puts JSON.pretty_generate(core)
                next
            end
 
            if input.start_with?("hours") then
                item = store.get(input[5, 99].strip.to_i)
                next if item.nil?
                hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
                Items::setAttribute(item["uuid"], "hours-1905", hours)
                next
            end
 
            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
