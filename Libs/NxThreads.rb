class NxThreads

    # --------------------------------------------------------------------------
    # Builders

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxThread", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxThreads::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        tx8 = Tx8s::make(parent["uuid"], 0)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        DarkEnergy::init("NxThread", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "parent", tx8)
        DarkEnergy::itemOrNull(uuid)
    end

    # --------------------------------------------------------------------------
    # Data

    # NxThreads::toString(thread)
    def self.toString(thread)
        padding = CatalystSharedCache::getOrDefaultValue("9c81e889-f07f-4f70-9e91-9bae2c097ea6", 0)
        hours = thread["hours"] || 2
        cr = NxThreads::completionRatio(thread)
        "🔺 #{thread["description"].ljust(padding)} (#{"%6.2f" % (100*cr)}% of #{"%5.2f" % hours} hours)"
    end

    # NxThreads::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxThread")
            .select{|item| item["parent"].nil? }
            .select{|thread| NxThreads::completionRatio(thread) < 1 }
            .sort_by{|thread| NxThreads::completionRatio(thread) }
    end

    # NxThreads::infinityuuid()
    def self.infinityuuid()
        "bc3901ad-18ad-4354-b90b-63f7a611e64e"
    end

    # NxThreads::interactivelySelectOrNull()
    def self.interactivelySelectOrNull()
        threads = DarkEnergy::mikuType("NxThread")
                    .sort_by{|thread| NxThreads::completionRatio(thread) }
        padding = threads.map{|item| NxThreads::toString(item).size }.max
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|item| "#{NxThreads::toString(item).ljust(padding)}" })
    end

    # NxThreads::interactivelySelectThreadAtMainListingOrNull()
    def self.interactivelySelectThreadAtMainListingOrNull()
        threads = DarkEnergy::mikuType("NxThread")
                    .select{|item| item["parent"].nil? }
                    .sort_by{|thread| NxThreads::completionRatio(thread) }
        padding = threads.map{|item| NxThreads::toString(item).size }.max
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|item| "#{NxThreads::toString(item).ljust(padding)}" })
    end

    # NxThreads::interactivelySelectThreadChildOfThisThreadOrNull(thread)
    def self.interactivelySelectThreadChildOfThisThreadOrNull(thread)
        threads = DarkEnergy::mikuType("NxThread")
                    .select{|item| item["parent"] and item["parent"]["uuid"] == thread["uuid"] }
                    .sort_by{|thread| NxThreads::completionRatio(thread) }
        padding = threads.map{|item| NxThreads::toString(item).size }.max
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|item| "#{NxThreads::toString(item).ljust(padding)}" })
    end

    # NxThreads::architectOrNull()
    def self.architectOrNull()
        thread = NxThreads::interactivelySelectOrNull()
        return thread if thread
        NxThreads::interactivelyIssueNewOrNull()
    end

    # NxThreads::completionRatio(thread)
    def self.completionRatio(thread)
        hours = thread["hours"] || 2
        Bank::recoveredAverageHoursPerDay(thread["uuid"]).to_f/(hours.to_f/7)
    end

    # NxThreads::childrenInOrder(thread)
    def self.childrenInOrder(thread)
        items  = Tx8s::childrenInOrder(thread)
        monitors, items = items.partition{|item| item["mikuType"] == "NxDelegate" }
        threads, items = items.partition{|item| item["mikuType"] == "NxThread" }
        monitors + items + threads.sort_by{|th| NxThreads::completionRatio(th) }
    end

    # NxThreads::childrenInOrderForPure(thread)
    def self.childrenInOrderForPure(thread)
        items  = Tx8s::childrenInOrder(thread)
        if NxThreads::completionRatio(thread) < 0.5 then

        else

        end


        monitors, items = items.partition{|item| item["mikuType"] == "NxDelegate" }
        threads, items = items.partition{|item| item["mikuType"] == "NxThread" }
        monitors + items + threads.sort_by{|th| NxThreads::completionRatio(th) }
    end

    # --------------------------------------------------------------------------
    # Ops

    # NxThreads::maintenance()
    def self.maintenance()
        # Ensuring consistency of parenting targets
        padding = DarkEnergy::mikuType("NxThread")
            .map{|item| item["description"].size }
            .reduce(0){|x, a| [x,a].max }
        CatalystSharedCache::set("9c81e889-f07f-4f70-9e91-9bae2c097ea6", padding)

        # Ensuring consistency of parenting targets
        DarkEnergy::mikuType("NxTask").each{|item|
            next if item["parent"].nil?
            if DarkEnergy::itemOrNull(item["parent"]["uuid"]).nil? then
                DarkEnergy::patch(uuid, "parent", nil)
            end
        }

        # Move orphan items to Infinity
        DarkEnergy::mikuType("NxTask").each{|item|
            next if item["parent"]
            parent = DarkEnergy::itemOrNull(NxThreads::infinityuuid())
            item["parent"] = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))
            DarkEnergy::commit(item)
        }
    end

    # NxThreads::program1(thread)
    def self.program1(thread)
        loop {

            thread = DarkEnergy::itemOrNull(thread["uuid"])
            return if thread.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            store.register(thread, false)
            spacecontrol.putsline Listing::toString2(store, thread)
            spacecontrol.putsline ""

            NxThreads::childrenInOrder(thread)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::toString2(store, item).gsub(thread["description"], "")
                    break if !status
                }

            puts ""
            puts "(task, pile, float, monitor, thread, position *, select tasks and move down)"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                NxTasks::interactivelyIssueNewAtParentOrNull(thread)
                next
            end

            if input == "pile" then
                Tx8s::pileAtThisParent(thread)
            end

            if input == "float" then
                NxDelegates::interactivelyIssueNewAtParentOrNull(thread)
                next
            end

            if input == "monitor" then
                NxDelegates::interactivelyIssueNewAtParentOrNull(thread)
                next
            end

            if input == "thread" then
                NxThreads::interactivelyIssueNewAtParentOrNull(thread)
                next
            end

            if input.start_with?("position") then
                itemindex = input[8, input.length].strip.to_i
                item = store.get(itemindex)
                return if item.nil?
                Tx8s::repositionItemAtSameParent(item)
                next
            end

            if input == "select tasks and move down" then
                unselected = NxThreads::childrenInOrder(thread)
                                .select{|item| item["mikuType"] == "NxTask" }
                selected, _ = LucilleCore::selectZeroOrMore("task", [], unselected, lambda{ |item| PolyFunctions::toString(item) })
                puts "Select target thread"
                t = NxThreads::interactivelySelectThreadChildOfThisThreadOrNull(thread)
                next if t.nil?
                selected.each{|task|
                    tx8 = Tx8s::make(t["uuid"], Tx8s::nextPositionAtThisParent(t))
                    DarkEnergy::patch(task["uuid"], "parent", tx8)
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
