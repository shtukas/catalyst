class NxThreads

    # --------------------------------------------------------------------------
    # Builders

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Cubes::init(nil, "NxThread", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::itemOrNull(uuid)
    end

    # --------------------------------------------------------------------------
    # Data

    # NxThreads::engineSuffixOrNull(thread)
    def self.engineSuffixOrNull(thread)
        return nil if !TxDrives::isActiveEngineItem(thread)
        ratio = TxDrives::ratio(thread)
        return nil if ratio.nil?
        percentage = 100*ratio
        " (priority: #{"%6.2f" % percentage}% of #{thread["priority"]["hours"]} hours)"
    end

    # NxThreads::toString(thread)
    def self.toString(thread)
        "⛵️ (#{"%5.2f" % thread["coordinate-nx129"]}) #{thread["description"]}#{NxThreads::engineSuffixOrNull(thread)}"
    end

    # NxThreads::interactivelySelectOrNull()
    def self.interactivelySelectOrNull()
        threads = Cubes::mikuType("TxCore")
                    .sort_by{|core| Catalyst::listingCompletionRatio(core) }
                    .map{|core| 
                        Cubes::mikuType("NxThread")
                            .select{|item| item["lineage-nx128"] == core["uuid"] }
                            .sort_by{|item| item["coordinate-nx129"] || 0 }
                    }
                    .flatten
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|item| "#{PolyFunctions::lineageSuffix(item).strip.yellow} #{NxThreads::toString(item)}" })
    end

    # NxThreads::architectOrNull()
    def self.architectOrNull()
        thread = NxThreads::interactivelySelectOrNull()
        return thread if thread
        NxThreads::interactivelyIssueNewOrNull()
    end

    # NxThreads::elementsInOrder(thread)
    def self.elementsInOrder(thread)
        Cubes::mikuType("NxTask")
            .select{|item| item["lineage-nx128"] == thread["uuid"] }
            .sort_by{|item| item["coordinate-nx129"] || 0 }
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
        elements = NxThreads::elementsInOrder(thread)
        elements.each{|item|
            puts PolyFunctions::toString(item)
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
        # Ensuring consistency of lineages

        Cubes::mikuType("NxThread").each{|thread|
            next if thread["lineage-nx128"]
            core = Cubes::itemOrNull("7cf30bc6-d791-4c0c-b03f-16c728396f22")  # Infinity Core
            if core.nil? then
                raise "error: B1204141-BBB8-4712-8238-0C1FC979D4B9"
            end
            position = TxCores::newFirstPosition(core)
            Cubes::setAttribute2(thread["uuid"], "lineage-nx128", core["uuid"])
            Cubes::setAttribute2(thread["uuid"], "coordinate-nx129", position)
        }

        Cubes::mikuType("NxThread").each{|thread|
            if thread["lineage-nx128"] then
                core = Cubes::itemOrNull(thread["lineage-nx128"])
                if core.nil? then
                    core = Cubes::itemOrNull("7cf30bc6-d791-4c0c-b03f-16c728396f22")  # Infinity Core
                    if core.nil? then
                        raise "error: 3CCCED4A-644A-42E1-B787-01686CAF57B4"
                    end
                    position = TxCores::newFirstPosition(core)
                    Cubes::setAttribute2(thread["uuid"], "lineage-nx128", core["uuid"])
                    Cubes::setAttribute2(thread["uuid"], "coordinate-nx129", position)
                end
            end
        }
    end

    # NxThreads::program1(thread)
    def self.program1(thread)
        loop {

            thread = Cubes::itemOrNull(thread["uuid"])
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
                    status = spacecontrol.putsline Listing::toString2(store, item).gsub("(#{thread["description"]})", "")
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
                Cubes::setAttribute2(task["uuid"], "lineage-nx128", thread["uuid"])
                Cubes::setAttribute2(task["uuid"], "coordinate-nx129", position)
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

                    Cubes::setAttribute2(t1["uuid"], "lineage-nx128", thread["uuid"])
                    Cubes::setAttribute2(t1["uuid"], "coordinate-nx129", position)
                }
                next
            end

            if Interpreting::match("position * *", input) then
                _, listord, position = Interpreting::tokenizer(input)
                item = store.get(listord.to_i)
                return if item.nil?
                Cubes::setAttribute2(item["uuid"], "coordinate-nx129", position.to_f)
                return
            end

            if input.start_with?("position") then
                itemindex = input[8, input.length].strip.to_i
                item = store.get(itemindex)
                next if item.nil?
                Cubes::setAttribute2(t1["uuid"], "coordinate-nx129", position)
                next
            end

            if input == "sort" then
                unselected = NxThreads::elementsInOrder(thread)
                selected, _ = LucilleCore::selectZeroOrMore("item", [], unselected, lambda{ |item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    Cubes::setAttribute2(task["uuid"], "coordinate-nx129", NxThreads::newFirstPosition(thread))
                }
            end

            if input == "move" then
                unselected = NxThreads::elementsInOrder(thread)
                selected, _ = LucilleCore::selectZeroOrMore("item", [], unselected, lambda{ |item| PolyFunctions::toString(item) })
                next if selected.empty?
                target = NxThreads::interactivelySelectOrNull()
                next if target.nil?
                selected.reverse.each{|item|
                    Cubes::setAttribute2(item["uuid"], "lineage-nx128", target["uuid"])
                    Cubes::setAttribute2(item["uuid"], "coordinate-nx129", NxThreads::newFirstPosition(target))
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

    # NxThreads::moveTasks(items)
    def self.moveTasks(items)
        thread = NxThreads::interactivelySelectOrNull()
        items.each{|item|
            Cubes::setAttribute2(item["uuid"], "lineage-nx128", thread["uuid"])
        }
    end
end
