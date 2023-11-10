
class NxThreads

    # -----------------------------------------------
    # Build

    # NxThreads::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        engine = TxEngines::interactivelyMakeNewOrNull()

        uuid = SecureRandom.uuid
        Updates::itemInit(uuid, "NxThread")

        Updates::itemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Updates::itemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Updates::itemAttributeUpdate(uuid, "description", description)
        Updates::itemAttributeUpdate(uuid, "engine-0916", engine)

        Broadcasts::publishItem(uuid)
        Catalyst::itemOrNull(uuid)
    end

    # -----------------------------------------------
    # Data

    # NxThreads::toString(item)
    def self.toString(item)
        padding = XCache::getOrDefaultValue("b1bd5d84-2051-432a-83d1-62ece0bf54f7", "0").to_i
        "⛵️ #{TxEngines::prefix2(item)}#{item["description"].ljust(padding)} (#{TxEngines::toString(item["engine-0916"]).green})"
    end

    # NxThreads::interactivelySelectOneOrNullUsingTopDownNavigation(context = nil)
    def self.interactivelySelectOneOrNullUsingTopDownNavigation(context =  nil)
        if context.nil? then
            threads = Catalyst::mikuType("NxThread")
                        .select{|item| item["parent-1328"].nil? }
            selected = LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|item| PolyFunctions::toString(item) })
            if selected then
                return NxThreads::interactivelySelectOneOrNullUsingTopDownNavigation(selected)
            else
                return nil
            end
        end
        threadKids = Catalyst::mikuType("NxThread").select{|t| t["parent-1328"] == context["uuid"] }
        if threadKids.size > 0 then
            store = []
            store << context
            puts "----------------------------"
            puts "0: context: #{PolyFunctions::toString(context)}"
            puts ""
            threadKids.each{|t|
                store << t
                puts "#{store.size-1}: #{NxThreads::toString(t)}"
            }
            indx = LucilleCore::askQuestionAnswerAsString("index of target (default to 0): ")
            if indx == "" then
                indx = 0
            else
                indx = indx.to_i
            end
            if indx == 0 then
                return context
            end
            target = store[indx]
            if target.nil? then
                return NxThreads::interactivelySelectOneOrNullUsingTopDownNavigation(context)
            else
                return NxThreads::interactivelySelectOneOrNullUsingTopDownNavigation(target)
            end
        else
            return context
        end
    end

    # NxThreads::listingItems()
    def self.listingItems()
        Catalyst::mikuType("NxThread")
            .select{|item| item["parent-1328"].nil? }
            .sort_by{|item| TxEngines::listingCompletionRatio(item) }
    end

    # NxThreads::children(thread)
    def self.children(thread)
        (Catalyst::mikuType("NxTask") + Catalyst::mikuType("NxThread"))
                .select{|item| item["parent-1328"] == thread["uuid"] }
    end

    # NxThreads::childrenInOrder(thread)
    def self.childrenInOrder(thread)
        if thread["uuid"] == "3d4a56c7-0215-4298-bd05-086113947dd2" then
            # In the case of "Perfection" we return this:
            return NxThreads::children(thread).sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
        end
        a, b = NxThreads::children(thread).partition{|item| item["engine-0916"] }
        a1, a2 = a.partition{|item| TxEngines::listingCompletionRatio(item["engine-0916"]) < 1 }
        b1, b2 = b.partition{|item| item["active"] }
        [
            a1.sort_by{|item| TxEngines::listingCompletionRatio(item["engine-0916"]) },
            b1.sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) },
            b2.sort_by{|item| item["unixtime"] },
            a2.sort_by{|item| TxEngines::listingCompletionRatio(item["engine-0916"]) }
        ]
            .flatten
    end

    # NxThreads::suffix(item)
    def self.suffix(item)
        return "" if item["parent-1328"].nil?
        parent = Catalyst::itemOrNull(item["parent-1328"])
        return "" if parent.nil?
        " (#{parent["description"]})".green
    end

    # -----------------------------------------------
    # Ops

    # NxThreads::program1(thread)
    def self.program1(thread)
        loop {

            thread = Catalyst::itemOrNull(thread["uuid"])
            return if thread.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(thread, false)
            puts  Listing::toString2(store, thread)
            puts  ""

            NxThreads::childrenInOrder(thread)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            puts "task | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Updates::itemAttributeUpdate(task["uuid"], "parent-1328", thread["uuid"])
                next
            end

            if input == "move" then
                Catalyst::selectSubsetAndMoveToSelectedThread(NxThreads::childrenInOrder())
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxThreads::interactivelySelectAndPutInThread(item) # boolean
    def self.interactivelySelectAndPutInThread(item)
        thread = NxThreads::interactivelySelectOneOrNullUsingTopDownNavigation()
        return false if thread.nil?

        if item["mikuType"] != "NxTask" and item["mikuType"] != "NxThread" then
            puts "The current mikuType of '#{PolyFunctions::toString(item).green}' is #{item["mikuType"].green}"
            puts "We need to convert it to a NxTask"
            if LucilleCore::askQuestionAnswerAsBoolean("> convert ? ", true) then
                (lambda {|item|
                    if item["mikuType"] == "NxOndate" then
                        Updates::itemAttributeUpdate(item["uuid"], "mikuType", "NxTask")
                        return
                    end
                    raise "(error: 9d319de8-879c-4cd7-9700-2bdf204b0a67) with mikuType: #{item["mikuType"]}"
                }).call(item)
            else
                return false
            end
        end

        Updates::itemAttributeUpdate(item["uuid"], "parent-1328", thread["uuid"])
        true
    end
end
