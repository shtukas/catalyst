class NxThreads

    # --------------------------------------------------------------------------
    # Builders

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        sortType = NxThreads::interactivelySelectSortType()
        uuid = SecureRandom.uuid
        Events::publishItemInit("NxThread", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "sortType", sortType)
        Catalyst::itemOrNull(uuid)
    end

    # --------------------------------------------------------------------------
    # type

    # NxThreads::sortTypes()
    def self.sortTypes()
        ["position-sort", "time-sort"]
    end

    # NxThreads::interactivelySelectSortType()
    def self.interactivelySelectSortType()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("sort type", NxThreads::sortTypes())
        return type if type
        NxThreads::interactivelySelectType()
    end

    # --------------------------------------------------------------------------
    # Data

    # NxThreads::toString(thread)
    def self.toString(thread)
        "🔸 #{TxEngine::prefix(thread)}#{thread["description"]} (#{thread["sortType"]})#{TxCores::suffix(thread)}"
    end

    # NxThreads::toStringPosition(thread)
    def self.toStringPosition(thread)
        "🔸 #{TxEngine::prefix(thread)}(#{"%5.2f" % (thread["coordinate-nx129"] || 0)}) #{thread["description"]} (#{thread["sortType"]})#{TxCores::suffix(thread)}"
    end

    # NxThreads::toStringTime(thread)
    def self.toStringTime(thread)
        "🔸 #{TxEngine::prefix(thread)}(#{"%5.2f" % Bank::recoveredAverageHoursPerDayCached(thread["uuid"]) }) #{thread["description"]} (#{thread["sortType"]})#{TxCores::suffix(thread)}"
    end

    # NxThreads::interactivelySelectOrNull()
    def self.interactivelySelectOrNull()
        threads = Catalyst::mikuType("NxThread")
        th1, th2 = threads.partition{|thread| thread["drive-nx1"] }
        threads = th1.sort_by{|thread| TxEngine::ratio(thread["drive-nx1"]) } + th2.sort_by{|thread| thread["unixtime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|item| "#{NxThreads::toString(item)}#{PolyFunctions::lineageSuffix(item).yellow}" })
    end

    # NxThreads::architectOrNull()
    def self.architectOrNull()
        thread = NxThreads::interactivelySelectOrNull()
        return thread if thread
        NxThreads::interactivelyIssueNewOrNull()
    end

    # NxThreads::elementsInOrder(thread)
    def self.elementsInOrder(thread)
        if thread["sortType"] == "position-sort" then
            return Todos::children(thread).sort_by{|item| item["coordinate-nx129"] || 0 }
        end
        if thread["sortType"] == "time-sort" then
            return Todos::children(thread).sort_by{|item| Bank::recoveredAverageHoursPerDayCached(item["uuid"]) }
        end
        raise "(error: bd8453d5-85bc-4da9-8bde-61431061ff65)"
    end

    # NxThreads::newFirstPosition(thread)
    def self.newFirstPosition(thread)
        elements = NxThreads::elementsInOrder(thread)
                        .select{|item| item["coordinate-nx129"] }
        return 1 if elements.empty?
        elements.map{|item| item["coordinate-nx129"] }.min - 1
    end

    # NxThreads::newNextPosition(thread)
    def self.newNextPosition(thread)
        elements = NxThreads::elementsInOrder(thread)
                        .select{|item| item["coordinate-nx129"] }
        return 1 if elements.empty?
        elements.map{|item| item["coordinate-nx129"] }.max + 1
    end

    # NxThreads::interactivelyDecidePositionAtThread(thread)
    def self.interactivelyDecidePositionAtThread(thread)
        if thread["sortType"] == "time-sort" then
            return rand
        end
        elements = NxThreads::elementsInOrder(thread)
        elements.each{|item|
            (lambda{|item|
                if item["mikuType"] == "NxTask" then
                    puts NxTasks::toStringPosition(item)
                    return 
                end
                puts PolyFunctions::toString(item)
            }).call(item)
            
        }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            return NxThreads::newNextPosition(thread)
        end
        position.to_f
    end

    # --------------------------------------------------------------------------
    # Ops

    # NxThreads::maintenance()
    def self.maintenance()
        Catalyst::mikuType("NxThread").each{|thread|
            next if thread["lineage-nx128"].nil?
            core = Catalyst::itemOrNull(thread["lineage-nx128"])
            next if core
            Events::publishItemAttributeUpdate(thread["uuid"], "lineage-nx128", core["uuid"])
        }
    end

    # NxThreads::program1(thread)
    def self.program1(thread)
        loop {

            thread = Catalyst::itemOrNull(thread["uuid"])
            return if thread.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            store.register(thread, false)
            spacecontrol.putsline Listing::toString2(store, thread)
            spacecontrol.putsline ""

            items = NxThreads::elementsInOrder(thread)
            items = items
                        .map{|item| Stratification::getItemStratification(item).reverse + [item] }
                        .flatten
            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::toString3(thread, store, item).gsub("(#{thread["description"]})", "")
                    break if !status
                }

            puts ""
            puts "(task, pile, position * *, sort, move)"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                position = NxThreads::newNextPosition(thread)
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                Events::publishItemAttributeUpdate(task["uuid"], "lineage-nx128", thread["uuid"])
                Events::publishItemAttributeUpdate(task["uuid"], "coordinate-nx129", position)
                next
            end

            if input == "pile" then
                text = CommonUtils::editTextSynchronously("").strip
                return if text == ""
                text.lines.to_a.map{|line| line.strip }.select{|line| line != ""}.reverse.each {|line|

                    position = NxThreads::newFirstPosition(thread)

                    t1 = NxTasks::descriptionToTask(line)
                    next if t1.nil?
                    puts JSON.pretty_generate(t1)

                    Events::publishItemAttributeUpdate(t1["uuid"], "lineage-nx128", thread["uuid"])
                    Events::publishItemAttributeUpdate(t1["uuid"], "coordinate-nx129", position)
                }
                next
            end

            if Interpreting::match("position * *", input) then
                _, listord, position = Interpreting::tokenizer(input)
                item = store.get(listord.to_i)
                return if item.nil?
                Events::publishItemAttributeUpdate(item["uuid"], "coordinate-nx129", position.to_f)
                next
            end

            if input.start_with?("position") then
                itemindex = input[8, input.length].strip.to_i
                item = store.get(itemindex)
                next if item.nil?
                Events::publishItemAttributeUpdate(item["uuid"], "coordinate-nx129", position)
                next
            end

            if input == "sort" then
                unselected = NxThreads::elementsInOrder(thread)
                selected, _ = LucilleCore::selectZeroOrMore("item", [], unselected, lambda{ |item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    Events::publishItemAttributeUpdate(task["uuid"], "coordinate-nx129", NxThreads::newFirstPosition(thread))
                }
            end

            if input == "move" then
                unselected = NxThreads::elementsInOrder(thread)
                selected, _ = LucilleCore::selectZeroOrMore("item", [], unselected, lambda{ |item| PolyFunctions::toString(item) })
                next if selected.empty?
                target = NxThreads::interactivelySelectOrNull()
                next if target.nil?
                selected.reverse.each{|item|
                    Events::publishItemAttributeUpdate(item["uuid"], "lineage-nx128", target["uuid"])
                    Events::publishItemAttributeUpdate(item["uuid"], "coordinate-nx129", NxThreads::newFirstPosition(target))
                }
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxThreads::program2()
    def self.program2()
        loop {
            thread = NxThreads::interactivelySelectOrNull()
            break if thread.nil?
            NxThreads::program1(thread)
        }
    end
end
