class NxCollections

    # NxCollections::interactivelyDecideHoursOrNull()
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

    # NxCollections::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        hours = NxCollections::interactivelyDecideHoursOrNull()
        Items::itemInit(uuid, "NxCollection")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "hours-1905", hours)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxCollections::icon(item)
    def self.icon(item)
        "🪔"
    end

    # NxCollections::ratio(item)
    def self.ratio(item)
        if item["hours-1905"].nil? then
            item["hours-1905"] = 1
        end
        [Bank1::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(item["hours-1905"].to_f/7)
    end

    # NxCollections::ratioString(item)
    def self.ratioString(item)
        return "" if item["hours-1905"].nil?
        " (#{"%6.2f" % (100 * NxCollections::ratio(item))} %; #{"%5.2f" % item["hours-1905"]} h/w)".yellow
    end

    # NxCollections::toString(item, context = nil)
    def self.toString(item, context = nil)
        if context == "thread-elements-listing" then
            return "(#{"%7.3f" % (item["global-positioning"] || 0)}) (#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxCollections::icon(item)} #{item["description"]}#{NxCollections::ratioString(item)}"
        end
        if context == "main-listing-1315" then
            return "#{NxCollections::icon(item)} #{item["description"]}#{NxCollections::ratioString(item)}"
        end
        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxCollections::icon(item)} #{item["description"]}#{NxCollections::ratioString(item)}"
    end

    # NxCollections::itemsInCompletionOrder()
    def self.itemsInCompletionOrder()
        Items::mikuType("NxCollection")
            .sort_by{|item| NxCollections::ratio(item) }
    end

    # NxCollections::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", NxCollections::itemsInCompletionOrder(), lambda{|item| PolyFunctions::toString(item) })
    end

    # NxCollections::numberOfChildrenWithHourCaching(parent)
    def self.numberOfChildrenWithHourCaching(parent)
        # data:
        #   - unixtime
        #   - number
        data = XCache::getOrNull("ab546cac-4b6a-4f59-a3e7-ea683a2e97f8:#{parent["uuid"]}")
        if data then
            data = JSON.parse(data)
            if (Time.new.to_i - data["unixtime"]) < 3600 then
                return data["number"]
            end
        end
        number = Catalyst::children(parent).size
        data = {
            "unixtime" => Time.new.to_i,
            "number" => number
        }
        XCache::set("ab546cac-4b6a-4f59-a3e7-ea683a2e97f8:#{parent["uuid"]}", JSON.generate(data))
        number
    end

    # NxCollections::childrenForPrefix(thread)
    def self.childrenForPrefix(thread)
        children = Catalyst::children(thread)
        c1, c2 = children.partition{|item| item["mikuType"] == "NxCollection" }
        [
            c1.sort_by{|item| NxCollections::ratio(item) }.select{|item| NxCollections::ratio(item) < 1 },
            c2.sort_by{|i| (i["global-positioning"] || 0) }
        ].flatten
    end

    # ------------------
    # Ops

    # NxCollections::program1(thread)
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

            children = Catalyst::childrenInGlobalPositioningOrder(thread)
            if thread["uuid"] == TxCores::infinityuuid() then
                children = children.first(40)
            end
            children
                .each{|element|
                    store.register(element, Listing::canBeDefault(element))
                    puts Listing::toString2(store, element, "thread-elements-listing")
                }

            puts ""

            puts "task | pile | position * | sort | moves"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                todo = NxTasks::interactivelyIssueNewOrNull()
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
                t2 = NxCollections::interactivelySelectOneOrNull()
                next if t2.nil?
                selected.each{|i| Items::setAttribute(i["uuid"], "parentuuid-0032", t2["uuid"]) }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxCollections::move(item)
    def self.move(item)
        thread = NxCollections::interactivelySelectOneOrNull()
        return if thread.nil?
        position = Catalyst::interactivelySelectPositionInParent(thread)
        Items::setAttribute(item["uuid"], "parentuuid-0032", thread["uuid"])
        Items::setAttribute(item["uuid"], "global-positioning", position)
    end
end
