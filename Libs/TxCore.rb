
class TxCores

    # -----------------------------------------------
    # Build

    # TxCores::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        engine = TxEngines::interactivelyMakeNewOrNull()

        uuid = SecureRandom.uuid
        Updates::itemInit(uuid, "TxCore")

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

    # TxCores::toString(item)
    def self.toString(item)
        padding = XCache::getOrDefaultValue("cb510e01-d829-4cfa-b502-b41bee7ffd0d", "0").to_i
        "☀️ #{TxEngines::prefix2(item)}#{item["description"].ljust(padding)} (#{TxEngines::toString(item["engine-0916"]).green})"
    end

    # TxCores::interactivelySelectOneOrNull(context = nil)
    def self.interactivelySelectOneOrNull(context =  nil)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", Catalyst::mikuType("TxCore"), lambda{|item| PolyFunctions::toString(item) })
    end

    # TxCores::listingItems()
    def self.listingItems()
        Catalyst::mikuType("TxCore")
            .sort_by{|item| TxEngines::listingCompletionRatio(item) }
    end

    # TxCores::children(core)
    def self.children(core)
        Catalyst::mikuType("NxThread")
                .select{|item| item["parent-1328"] == core["uuid"] }
    end

    # -----------------------------------------------
    # Ops

    # TxCores::pile3(item)
    def self.pile3(item)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.uuid, line)
                puts JSON.pretty_generate(task)
                Updates::itemAttributeUpdate(task["uuid"], "parent-1328", item["uuid"])
            }
    end

    # TxCores::program1(thread)
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

            TxCores::childrenInSortingStyleOrder(thread)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  "(#{"%6.2f" % (item["global-position"] || 0)}) #{Listing::toString2(store, item)}"
                }

            puts ""
            puts "task | pile | position * | sort | move"
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
                TxCores::pile3(thread)
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
                items = TxCores::childrenInSortingStyleOrder(thread)
                selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    Updates::itemAttributeUpdate(item["uuid"], "global-position", Catalyst::gloalFirstPosition()-1)
                }
                next
            end

            if input == "move" then
                Catalyst::selectSubsetAndMoveToSelectedThread(TxCores::childrenInSortingStyleOrder(thread))
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # TxCores::interactivelySelectAndInstallInThread(item) # boolean
    def self.interactivelySelectAndInstallInThread(item)
        thread = TxCores::interactivelySelectOneOrNullUsingTopDownNavigation(nil)
        return false if thread.nil?
        children = TxCores::childrenInSortingStyleOrder(thread)
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
