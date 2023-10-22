
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
        Updates::itemAttributeUpdate(uuid, "global-position", rand)

        Broadcasts::publishItem(uuid)
        Catalyst::itemOrNull(uuid)
    end

    # -----------------------------------------------
    # Data

    # NxThreads::toString(item)
    def self.toString(item)
        padding = XCache::getOrDefaultValue("b1bd5d84-2051-432a-83d1-62ece0bf54f7", "0").to_i
        st = item["sorting-style"] ? " (#{item["sorting-style"]})" : ""
        "⛵️ #{TxEngines::prefix2(item)}#{item["description"].ljust(padding)} (#{TxEngines::toString(item["engine-0916"]).green})#{st}"
    end

    # NxThreads::interactivelySelectOneOrNullUsingTopDownNavigation(context = nil)
    def self.interactivelySelectOneOrNullUsingTopDownNavigation(context =  nil)
        if context.nil? then
            threads = Catalyst::mikuType("NxThread")
                        .select{|item| item["parent-1328"].nil? }
                        .sort_by{|item| TxEngines::listingCompletionRatio(item["engine-0916"]) }
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
            indx = LucilleCore::askQuestionAnswerAsString("index of target: ").to_i
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
            puts "About to return '#{PolyFunctions::toString(context).green}'"
            LucilleCore::pressEnterToContinue()
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

    # NxThreads::childrenInSortingStyleOrder(thread)
    def self.childrenInSortingStyleOrder(thread)
        if thread["sorting-style"].nil? or thread["sorting-style"] == "linear" then
            return NxThreads::children(thread).sort_by{|item| item["global-position"] || 0 }
        end
        if thread["sorting-style"] == "perfection" then
            return NxThreads::children(thread)
                    .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
        end
        if thread["sorting-style"] == "top3" then
            items = NxThreads::children(thread).sort_by{|item| item["global-position"] || 0 }
            return items.take(3).sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) } + items.drop(3)
        end
        raise "(error: EE0A2644-BD60-44EB-A5CA-B620B0EEE992)"
    end

    # NxThreads::suffix(item)
    def self.suffix(item)
        return "" if item["parent-1328"].nil?
        parent = Catalyst::itemOrNull(item["parent-1328"])
        return "" if parent.nil?
        " (#{parent["description"]})".green
    end

    # NxThreads::interactivelySelectSortingStyleOrNull()
    def self.interactivelySelectSortingStyleOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("sorting-style", ["linear", "perfection", "top3"])
    end

    # NxThreads::firstPositionAtThread(thread)
    def self.firstPositionAtThread(thread)
        NxThreads::children(thread).reduce(0){|position, item|
            [position, item["global-position"] || 0].min
        }
    end

    # NxThreads::lastPositionAtThread(thread)
    def self.lastPositionAtThread(thread)
        NxThreads::children(thread).reduce(0){|position, item|
            [position, item["global-position"] || 0].max
        }
    end

    # -----------------------------------------------
    # Ops

    # NxThreads::pile3(thread)
    def self.pile3(thread)
        raise "(error: fff05fbf-7ad5-4ea4-ad88-47da74e20c97)" if thread["mikuType"] != "NxThread"
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.uuid, line)
                puts JSON.pretty_generate(task)
                position = NxThreads::firstPositionAtThread(thread) - 1
                Updates::itemAttributeUpdate(task["uuid"], "global-position", position)
                Updates::itemAttributeUpdate(task["uuid"], "parent-1328", thread["uuid"])
            }
    end

    # NxThreads::append(thread)
    def self.append(thread)
        raise "(error: fff05fbf-7ad5-4ea4-ad88-47da74e20c97)" if thread["mikuType"] != "NxThread"
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.uuid, line)
                puts JSON.pretty_generate(task)
                position = NxThreads::lastPositionAtThread(thread) + 1
                Updates::itemAttributeUpdate(task["uuid"], "global-position", position)
                Updates::itemAttributeUpdate(task["uuid"], "parent-1328", thread["uuid"])
            }
    end


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

            NxThreads::childrenInSortingStyleOrder(thread)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  "(#{"%6.2f" % (item["global-position"] || 0)}) #{Listing::toString2(store, item)}"
                }

            puts ""
            puts "task | pile | append | position * | sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Updates::itemAttributeUpdate(task["uuid"], "parent-1328", thread["uuid"])
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                Updates::itemAttributeUpdate(task["uuid"], "global-position", position)
                next
            end

            if input == "pile" then
                NxThreads::pile3(thread)
                next
            end

            if input == "append" then
                NxThreads::append(thread)
                next
            end

            if Interpreting::match("position *", input) then
                _, listord = Interpreting::tokenizer(input)
                item = store.get(listord.to_i)
                next if item.nil?
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                Updates::itemAttributeUpdate(item["uuid"], "global-position", position)
                next
            end

            if Interpreting::match("sort", input) then
                if thread["sorting-style"] == "perfection" then
                    puts "We are not sorting, threads with sorting-style perfection"
                    LucilleCore::pressEnterToContinue()
                end
                items = NxThreads::childrenInSortingStyleOrder(thread)
                selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    Updates::itemAttributeUpdate(item["uuid"], "global-position", Catalyst::gloalFirstPosition()-1)
                }
                next
            end

            if input == "move" then
                Catalyst::selectSubsetAndMoveToSelectedThread(NxThreads::childrenInSortingStyleOrder(thread))
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxThreads::interactivelySelectAndInstallInThread(item) # boolean
    def self.interactivelySelectAndInstallInThread(item)
        thread = NxThreads::interactivelySelectOneOrNullUsingTopDownNavigation(nil)
        return false if thread.nil?
        children = NxThreads::childrenInSortingStyleOrder(thread)
        children
            .first(40)
            .each{|task|
                puts "(#{"%6.2f" % (task["global-position"] || 0)}) #{PolyFunctions::toString(task)}"
            }
        position = LucilleCore::askQuestionAnswerAsString("> position (top, next # default): ")
        position = lambda {|position|
            if position == "top" then
                return ([1] + children.map{|item| item["global-position"] }.compact).min - 1
            end
            if position == "" or position == "next" then
                return ([1] + children.map{|item| item["global-position"] }.compact).max + 1
            end
            position.to_f
        }.call(position)
        Updates::itemAttributeUpdate(item["uuid"], "parent-1328", thread["uuid"])
        Updates::itemAttributeUpdate(item["uuid"], "global-position", position)
        true
    end
end
