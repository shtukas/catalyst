class NxThreads

    # --------------------------------------------------------------------------
    # Builders

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        BladesGI::init("NxThread", uuid)
        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::itemOrNull(uuid)
    end

    # NxThreads::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        BladesGI::init("NxThread", uuid)
        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)

        position = Tx8s::interactivelyDecidePositionUnderThisParentOrNull(parent)
        if position then
            tx8 = Tx8s::make(parent["uuid"], position)
            BladesGI::setAttribute2(uuid, "parent", tx8)
        end

        BladesGI::itemOrNull(uuid)
    end

    # --------------------------------------------------------------------------
    # Data

    # NxThreads::toString(thread)
    def self.toString(thread)
        padding = XCache::getOrDefaultValue("9c81e889-f07f-4f70-9e91-9bae2c097ea6", "0").to_i
        hours = thread["hours"] || 2
        cr = Catalyst::listingCompletionRatio(thread)
        "🐙#{Tx8s::positionInParentSuffix(thread)} #{thread["description"].ljust(padding)} (#{"%6.2f" % (100*cr)}% of #{"%5.2f" % hours} hours)"
    end

    # NxThreads::interactivelySelectOrNull()
    def self.interactivelySelectOrNull()
        threads1 = BladesGI::mikuType("NxThread").select{|thread| thread["parent"].nil? }

        threads2 = BladesGI::mikuType("TxCore")
                    .sort_by{|core| Catalyst::listingCompletionRatio(core) }
                    .map{|core|
                        BladesGI::mikuType("NxThread")
                            .select{|thread| thread["parent"] and thread["parent"]["uuid"] == core["uuid"] }
                            .sort_by{|thread| Catalyst::listingCompletionRatio(thread) }
                    }
                    .flatten

        threads = threads1 + threads2
        padding = threads.map{|item| NxThreads::toString(item).size }.max
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|item| "#{NxThreads::toString(item).ljust(padding)}#{Tx8s::suffix(item).green}" })
    end

    # NxThreads::interactivelySelectThreadChildOfThisThreadOrNull(thread)
    def self.interactivelySelectThreadChildOfThisThreadOrNull(thread)
        threads = BladesGI::mikuType("NxThread")
                    .select{|item| item["parent"] and item["parent"]["uuid"] == thread["uuid"] }
                    .sort_by{|thread| Catalyst::listingCompletionRatio(thread) }
        padding = threads.map{|item| NxThreads::toString(item).size }.max
        LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|item| "#{NxThreads::toString(item).ljust(padding)}" })
    end

    # NxThreads::architectOrNull()
    def self.architectOrNull()
        thread = NxThreads::interactivelySelectOrNull()
        return thread if thread
        NxThreads::interactivelyIssueNewOrNull()
    end

    # NxThreads::orphanItems()
    def self.orphanItems()
        BladesGI::mikuType("NxThread")
            .select{|item| item["parent"].nil? }
    end

    # --------------------------------------------------------------------------
    # Ops

    # NxThreads::maintenance1()
    def self.maintenance1()
        padding = BladesGI::mikuType("NxThread")
            .map{|item| item["description"].size }
            .reduce(0){|x, a| [x,a].max }
        XCache::set("9c81e889-f07f-4f70-9e91-9bae2c097ea6", padding)
    end

    # NxThreads::maintenance2()
    def self.maintenance2()
        # Ensuring consistency of parenting targets
        BladesGI::mikuType("NxTask").each{|item|
            next if item["parent"].nil?
            if BladesGI::itemOrNull(item["parent"]["uuid"]).nil? then
                BladesGI::setAttribute2(uuid, "parent", nil)
            end
        }
    end

    # NxThreads::program1(thread)
    def self.program1(thread)
        loop {

            thread = BladesGI::itemOrNull(thread["uuid"])
            return if thread.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            store.register(thread, false)
            spacecontrol.putsline Listing::toString2(store, thread)
            spacecontrol.putsline ""

            stack = Stack::items()
            if stack.size > 0 then
                spacecontrol.putsline "stack:".green
                stack
                    .each{|item|
                        spacecontrol.putsline PolyFunctions::toString(item)
                    }
                spacecontrol.putsline ""
            end

            items = Tx8s::childrenInOrder(thread)

            if items.any?{|item| item["priority"] } then
                items = items
                    .select{|item| item["priority"] }
                    .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
            end

            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::toString2(store, item).gsub(thread["description"], "")
                    break if !status
                }

            puts ""
            puts "(task, pile, delegate, thread, position *, sort, select children and move them)"
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

            if input == "delegate" then
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
                next if item.nil?
                Tx8s::repositionItemAtSameParent(item)
                next
            end

            if input == "sort" then
                unselected = Tx8s::childrenInOrder(core)
                selected, _ = LucilleCore::selectZeroOrMore("item", [], unselected, lambda{ |item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    tx8 = Tx8s::make(core["uuid"], Tx8s::newFirstPositionAtThisParent(core))
                    BladesGI::setAttribute2(item["uuid"], "parent", tx8)
                }
            end

            if input == "select children and move them" then
                unselected = Tx8s::childrenInOrder(thread)
                selected, _ = LucilleCore::selectZeroOrMore("item", [], unselected, lambda{ |item| PolyFunctions::toString(item) })
                puts "Select new parent"
                parent = Tx8s::interactivelySelectParentOrNull(nil)
                next if parent.nil?
                selected.reverse.each{|item|
                    tx8 = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))
                    BladesGI::setAttribute2(item["uuid"], "parent", tx8)
                }
            end

            if input == "unstack" then
                Stack::unstackOntoParentAttempt(thread)
                next
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
