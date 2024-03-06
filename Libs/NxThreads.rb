
class NxThreads

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes2::itemInit(uuid, "NxThread")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxThreads::icon(item)
    def self.icon(item)
        "🔸"
    end

    # NxThreads::toString(item, context = nil)
    def self.toString(item, context = nil)
        if context == "work-listing-1633" then
            return "#{NxThreads::icon(item)} #{item["description"]}"
        end
        if context == "main-listing-1635" then
            return "#{NxThreads::icon(item)} #{item["description"]}"
        end
        "(#{"%7.3f" % (item["global-positioning"] || 0)}) #{NxThreads::icon(item)} #{item["description"]}"
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
        ([0] + NxThreads::children(item).map{|task| task["global-positioning"] || 0 }).min
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

    # NxThreads::muiItems()
    def self.muiItems()
        t1 = Cubes2::mikuType("TxCore")
                .select{|item| TxCores::ratio(item) < 1 }
                .sort_by{|item| TxCores::ratio(item) }
                .map{|core|
                    TxCores::listingElementsForCore(core)
                        .select{|item| Bank2::recoveredAverageHoursPerDay(item["uuid"]) < 1 }
                }
                .flatten
        t2 = NxThreads::threadsAndTodosInGlobalPositioningOrder()
                .select{|item| Bank2::recoveredAverageHoursPerDay(item["uuid"]) < 1 }
        (t1 + t2)
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
    end

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", NxThreads::itemsInGlobalPositioningOrder(), lambda{|item| PolyFunctions::toString(item) })
    end

    # NxThreads::children(parent)
    def self.children(parent)
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == parent["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxThreads::interactivelySelectPositionInThread(container)
    def self.interactivelySelectPositionInThread(container)
        elements = NxThreads::children(container)
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
        position = position.to_f
        position
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

            NxThreads::children(thread)
                .each{|element|
                    store.register(element, MainUserInterface::canBeDefault(element))
                    puts MainUserInterface::toString2(store, element, "listing-in-thread")
                }

            puts ""

            puts "todo | insert | position * | sort | select | dump"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                task = NxTodos::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", thread["uuid"])
                position = NxThreads::interactivelySelectPositionInThread(thread)
                Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                next
            end

            if input == "insert" then
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                text = CommonUtils::editTextSynchronously("").strip
                next if text == ""
                descriptions = text.lines.map{|line| line.strip }.select{|line| line != "" }
                positions = Catalyst::insertionPositions(thread, position, descriptions.size)
                descriptions.zip(positions).each{|description, position|
                        task = NxTodos::descriptionToTask1(SecureRandom.hex, description)
                        puts JSON.pretty_generate(task)
                        Cubes2::setAttribute(task["uuid"], "parentuuid-0032", thread["uuid"])
                        Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                }
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = NxThreads::interactivelySelectPositionInThread(thread)
                next if position.nil?
                Cubes2::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], NxThreads::children(thread), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxThreads::topPositionAmongChildren(thread) - 1)
                }
                next
            end

            if input == "select" then
                selected, _ = LucilleCore::selectZeroOrMore("item", [], NxThreads::children(thread), lambda{|i| PolyFunctions::toString(i) })
                uuids = JSON.parse(XCache::getOrDefaultValue("43ef5eda-d16d-483f-a438-e98d437bedda", "[]"))
                uuids = (uuids + selected.map{|item| item["uuid"]}).uniq
                XCache::set("43ef5eda-d16d-483f-a438-e98d437bedda", JSON.generate(uuids))
                next
            end

            if input == "dump" then
                uuids = JSON.parse(XCache::getOrDefaultValue("43ef5eda-d16d-483f-a438-e98d437bedda", "[]"))
                uuids.each{|uuid|
                    item = Cubes2::itemOrNull(uuid)
                    next if item.nil?
                    Cubes2::setAttribute(item["uuid"], "parentuuid-0032", thread["uuid"])
                }
                XCache::set("43ef5eda-d16d-483f-a438-e98d437bedda", "[]")
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxThreads::program2()
    def self.program2()
        loop {

            elements = (Cubes2::mikuType("NxThread") + NxTodos::orphans())
                        .sort_by{|item| item["global-positioning"] || 0 }

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

            elements
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item)
                }

            puts ""

            Cubes2::mikuType("TxCore")
                .sort_by{|item| TxCores::ratio(item) }
                .each{|item|
                    store.register(item, false)
                    puts MainUserInterface::toString2(store, item)
                }

            puts ""
            puts "todo | thread | sort | select | dump (at top)"
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
                thread = NxThreads::interactivelyIssueNewOrNull()
                next if thread.nil?
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                Cubes2::setAttribute(thread["uuid"], "global-positioning", position)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], elements, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxThreads::topPositionAmongThreads() - 1)
                }
                next
            end

            if input == "select" then
                selected, _ = LucilleCore::selectZeroOrMore("item", [], NxTodos::orphans(), lambda{|i| PolyFunctions::toString(i) })
                uuids = JSON.parse(XCache::getOrDefaultValue("43ef5eda-d16d-483f-a438-e98d437bedda", "[]"))
                uuids = (uuids + selected.map{|item| item["uuid"]}).uniq
                XCache::set("43ef5eda-d16d-483f-a438-e98d437bedda", JSON.generate(uuids))
                next
            end

            if input == "dump" then
                uuids = JSON.parse(XCache::getOrDefaultValue("43ef5eda-d16d-483f-a438-e98d437bedda", "[]"))
                uuids.each{|uuid|
                    item = Cubes2::itemOrNull(uuid)
                    next if item.nil?
                    Cubes2::setAttribute(item["uuid"], "parentuuid-0032", nil)
                    Cubes2::setAttribute(item["uuid"], "global-positioning", NxThreads::topPositionAmongThreads() - 1)
                }
                XCache::set("43ef5eda-d16d-483f-a438-e98d437bedda", "[]")
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
end
