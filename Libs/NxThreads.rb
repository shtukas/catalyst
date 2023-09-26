class NxThreads

    # --------------------------------------------------------------------------
    # Builders

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Events::publishItemInit("NxThread", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Catalyst::itemOrNull(uuid)
    end

    # --------------------------------------------------------------------------
    # Data

    # NxThreads::toString(item)
    def self.toString(item)
        "🔸 #{TxEngine::prefix(item)}#{item["description"]}#{TxCores::suffix(item)}"
    end

    # NxThreads::interactivelySelectOrNull()
    def self.interactivelySelectOrNull()
        threads = Catalyst::mikuType("NxThread")
        th1, th2 = threads.partition{|thread| thread["engine-0852"] }
        threads = th1.sort_by{|thread| TxEngine::ratio(thread["engine-0852"]) }.reverse + th2.sort_by{|thread| thread["unixtime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|item| "#{NxThreads::toString(item)}#{PolyFunctions::lineageSuffix(item).yellow}" })
    end

    # NxThreads::architectOrNull()
    def self.architectOrNull()
        thread = NxThreads::interactivelySelectOrNull()
        return thread if thread
        NxThreads::interactivelyIssueNewOrNull()
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

            items = Catalyst::children(thread)
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
            puts "(task, move)"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                Events::publishItemAttributeUpdate(task["uuid"], "lineage-nx128", thread["uuid"])
                next
            end

            if input == "move" then
                unselected = Catalyst::children(thread)
                selected, _ = LucilleCore::selectZeroOrMore("item", [], unselected, lambda{ |item| PolyFunctions::toString(item) })
                next if selected.empty?
                target = NxThreads::interactivelySelectOrNull()
                next if target.nil?
                selected.reverse.each{|item|
                    Events::publishItemAttributeUpdate(item["uuid"], "lineage-nx128", target["uuid"])
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
