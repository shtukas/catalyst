
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
        "🔺"
    end

    # NxThreads::activeListingRatio(item)
    def self.activeListingRatio(item)
        raise "(error: b8a8b117-b8a5-4b74-81ff-5d3aa1803d27) item: #{item}" if item["hours-1432"].nil?
        raise "(error: 8a2b0d8a-31fd-456b-aaf0-b296a0e8a86d) item: #{item}" if item["hours-1432"] == 0
        Bank2::recoveredAverageHoursPerDay(item["uuid"]).to_f/item["hours-1432"]
    end

    # NxThreads::toString(item, context = nil)
    def self.toString(item, context = nil)
        activity = item["hours-1432"] ? " (#{"%5.2f" % NxThreads::activeListingRatio(item)}, active: #{"%5.2f" % item["hours-1432"]})".green : "                       "
        positioning = item["hours-1432"] ? "         " : "(#{"%7.3f" % (item["global-positioning"] || 0)})"
        "#{positioning} #{NxThreads::icon(item)}#{activity} #{item["description"]}"
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

    # NxThreads::itemsInOrder1()
    def self.itemsInOrder1()
        threads = Cubes2::mikuType("NxThread")
        t1, t2 = threads.partition{|item| item["hours-1432"] }
        [
            t1.sort_by{|item| NxThreads::activeListingRatio(item) },
            t2.sort_by{|item| item["global-positioning"] || 0 }
        ].flatten
    end

    # NxThreads::threadsAndTodosInOrder1()
    def self.threadsAndTodosInOrder1()
        items = (Cubes2::mikuType("NxThread") + NxTodos::orphans())
        t1, t2 = items.partition{|item| item["hours-1432"] }
        [
            t1.sort_by{|item| NxThreads::activeListingRatio(item) },
            t2.sort_by{|item| item["global-positioning"] || 0 }
        ].flatten
    end

    # NxThreads::muiItems()
    def self.muiItems()
        NxThreads::threadsAndTodosInOrder1()
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

    # NxThreads::program1(block)
    def self.program1(block)
        loop {

            block = Cubes2::itemOrNull(block["uuid"])
            return if block.nil?

            system("clear")

            store = ItemStore.new()

            puts ""

            store.register(block, false)
            puts MainUserInterface::toString2(store, block, "inventory")
            puts ""

            NxThreads::children(block)
                .each{|element|
                    store.register(element, MainUserInterface::canBeDefault(element))
                    puts MainUserInterface::toString2(store, element, "listing-in-block")
                }

            puts ""

            puts "todo | insert | position * | sort | move | select"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                task = NxTodos::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", block["uuid"])
                position = Catalyst::interactivelySelectPositionInContainerOrNull(block)
                Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                next
            end

            if input == "insert" then
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                text = CommonUtils::editTextSynchronously("").strip
                next if text == ""
                descriptions = text.lines.map{|line| line.strip }.select{|line| line != "" }
                positions = Catalyst::insertionPositions(orbital, position, descriptions.size)
                descriptions.zip(positions).each{|description, position|
                        task = NxTodos::descriptionToTask1(SecureRandom.hex, description)
                        puts JSON.pretty_generate(task)
                        Cubes2::setAttribute(task["uuid"], "parentuuid-0032", orbital["uuid"])
                        Cubes2::setAttribute(task["uuid"], "global-positioning", position)
                }
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = Catalyst::interactivelySelectPositionInContainerOrNull(block)
                next if position.nil?
                Cubes2::setAttribute(i["uuid"], "global-positioning", position)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], NxThreads::children(block), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxThreads::topPositionAmongChildren(block) - 1)
                }
                next
            end

            if input == "move" then
                Catalyst::selectSubsetOfItemsAndMoveToSelectedContainer(NxThreads::children(block))
                next
            end

            if input == "select" then
                selected, _ = LucilleCore::selectZeroOrMore("item", [], NxThreads::children(block), lambda{|i| PolyFunctions::toString(i) })
                uuids = JSON.parse(XCache::getOrDefaultValue("43ef5eda-d16d-483f-a438-e98d437bedda", "[]"))
                uuids = (uuids + selected.map{|item| item["uuid"]}).uniq
                XCache::set("43ef5eda-d16d-483f-a438-e98d437bedda", JSON.generate(uuids))
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxThreads::program2()
    def self.program2()
        loop {

            elements = NxThreads::threadsAndTodosInOrder1()

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
            puts "thread | sort | select | make"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

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

            if input == "make" then
                thread = NxThreads::interactivelyIssueNewOrNull()
                next if thread.nil?

                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                Cubes2::setAttribute(thread["uuid"], "global-positioning", position)

                uuids = JSON.parse(XCache::getOrDefaultValue("43ef5eda-d16d-483f-a438-e98d437bedda", "[]"))
                uuids.each{|uuid|
                    item = Cubes2::itemOrNull(uuid)
                    next if item.nil?
                    Cubes2::setAttribute(item["uuid"], "parentuuid-0032", thread["uuid"])
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

    # NxThreads::setHours(item, priority)
    def self.setHours(item, priority)
        Cubes2::setAttribute(item["uuid"], "hours-1432", priority)
    end

    # NxThreads::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", NxThreads::itemsInOrder1(), lambda{|item| PolyFunctions::toString(item) })
    end

    # NxThreads::children(parent)
    def self.children(parent)
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == parent["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end
end
