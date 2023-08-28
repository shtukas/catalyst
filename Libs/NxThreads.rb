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

    # NxThreads::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        Cubes::init(nil, "NxThread", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)

        position = Tx8s::interactivelyDecidePositionUnderThisParentOrNull(parent)
        if position then
            tx8 = Tx8s::make(parent["uuid"], position)
            Cubes::setAttribute2(uuid, "parent", tx8)
        end

        Cubes::itemOrNull(uuid)
    end

    # --------------------------------------------------------------------------
    # Data

    # NxThreads::toString(thread)
    def self.toString(thread)
        "🐙#{Tx8s::positionInParentSuffix(thread)} #{thread["description"]}"
    end

    # NxThreads::interactivelySelectOrNull()
    def self.interactivelySelectOrNull()
        threads1 = Cubes::mikuType("NxThread").select{|thread| thread["parent"].nil? }

        threads2 = Cubes::mikuType("TxCore")
                    .sort_by{|core| Catalyst::listingCompletionRatio(core) }
                    .map{|core|
                        Cubes::mikuType("NxThread")
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
        threads = Cubes::mikuType("NxThread")
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
        Cubes::mikuType("NxThread")
            .select{|item| item["parent"].nil? }
    end

    # --------------------------------------------------------------------------
    # Ops

    # NxThreads::maintenance2()
    def self.maintenance2()
        # Ensuring consistency of parenting targets
        Cubes::mikuType("NxTask").each{|item|
            next if item["parent"].nil?
            if Cubes::itemOrNull(item["parent"]["uuid"]).nil? then
                Cubes::setAttribute2(uuid, "parent", nil)
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

            items = Tx8s::childrenInOrder(thread)
            items = items
                        .map{|item| Stratification::getItemStratification(item).reverse + [item] }
                        .flatten
            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::toString2(store, item).gsub(thread["description"], "")
                    break if !status
                }

            puts ""
            puts "(task, pile, delegate, thread, position *, sort, move)"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                NxTasks::interactivelyIssueNewAtParentOrNull(thread)
                next
            end

            if input == "pile" then
                Tx8s::pileAtThisParent(thread)
                next
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
                unselected = Tx8s::childrenInOrder(thread)
                selected, _ = LucilleCore::selectZeroOrMore("item", [], unselected, lambda{ |item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    tx8 = Tx8s::make(thread["uuid"], Tx8s::newFirstPositionAtThisParent(thread))
                    Cubes::setAttribute2(item["uuid"], "parent", tx8)
                }
            end

            if input == "move" then
                Tx8s::selectChildrenAndMove(thread)
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
