
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

    # NxThreads::childrenInIntelligentOrder(thread)
    def self.childrenInIntelligentOrder(thread)
        a, b = NxThreads::children(thread).partition{|item| item["engine-0916"] }
        a1, a2 = a.partition{|item| TxEngines::listingCompletionRatio(item["engine-0916"]) < 1 }
        b = b.sort_by{|item| item["global-position"] || 0 }
        [
            a1.sort_by{|item| TxEngines::listingCompletionRatio(item["engine-0916"]) },
            b.take(3).sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) } + b.drop(3),
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

            NxThreads::childrenInIntelligentOrder(thread)
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
                items = NxThreads::childrenInIntelligentOrder(thread)
                selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    Updates::itemAttributeUpdate(item["uuid"], "global-position", Catalyst::gloalFirstPosition()-1)
                }
                next
            end

            if input == "move" then
                Catalyst::selectSubsetAndMoveToSelectedThread(NxThreads::childrenInIntelligentOrder(thread))
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxThreads::interactivelySelectThreadAndPositionInThreadOrNull() # null or [thread, position]
    def self.interactivelySelectThreadAndPositionInThreadOrNull()
        thread = NxThreads::interactivelySelectOneOrNullUsingTopDownNavigation(nil)
        return nil if thread.nil?
        children = NxThreads::childrenInIntelligentOrder(thread)
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
        [thread, position]
    end

    # NxThreads::interactivelySelectAndInstallInThread(item) # boolean
    def self.interactivelySelectAndInstallInThread(item)
        coordinates = NxThreads::interactivelySelectThreadAndPositionInThreadOrNull()
        return false if coordinates.nil?
        thread, position = coordinates

        if item["mikuType"] != "NxTask" then
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
        Updates::itemAttributeUpdate(item["uuid"], "global-position", position)
        true
    end
end
