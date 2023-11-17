
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

        Broadcasts::publishItem(uuid)
        Catalyst::itemOrNull(uuid)
    end

    # -----------------------------------------------
    # Data

    # TxCores::toString(item)
    def self.toString(item)
        padding = XCache::getOrDefaultValue("b1bd5d84-2051-432a-83d1-62ece0bf54f7", "0").to_i
        "⏱️ #{TxEngines::string1(item).green} #{item["description"].ljust(padding)}#{TxEngines::string2(item).green}"
    end

    # TxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        cores = Catalyst::mikuType("TxCore")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|item| PolyFunctions::toString(item) })
    end

    # TxCores::listingItems()
    def self.listingItems()
        Catalyst::mikuType("TxCore")
            .select{|item| TxEngines::dailyRelativeCompletionRatio(item["engine-0916"]) < 1 }
            .sort_by{|core| TxEngines::dailyRelativeCompletionRatio(core["engine-0916"]) }
    end

    # TxCores::children(core)
    def self.children(core)
        Catalyst::mikuType("NxTask")
                .select{|item| item["coreX-2137"] == core["uuid"] }
    end

    # TxCores::childrenInOrder(core)
    def self.childrenInOrder(core)
        if core["uuid"] == "3d4a56c7-0215-4298-bd05-086113947dd2" then
            # In the case of "Perfection" we return this:
            return TxCores::children(core).sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
        end
        a, b = TxCores::children(core).partition{|item| item["engine-0916"] }
        a1, a2 = a.partition{|item| TxEngines::dailyRelativeCompletionRatio(item["engine-0916"]) < 1 }
        b1, b2 = b.partition{|item| item["active"] }
        [
            a1.sort_by{|item| TxEngines::dailyRelativeCompletionRatio(item["engine-0916"]) },
            b1.sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) },
            b2.sort_by{|item| item["unixtime"] },
            a2.sort_by{|item| TxEngines::dailyRelativeCompletionRatio(item["engine-0916"]) }
        ]
            .flatten
    end

    # TxCores::suffix(item)
    def self.suffix(item)
        return "" if item["coreX-2137"].nil?
        parent = Catalyst::itemOrNull(item["coreX-2137"])
        return "" if parent.nil?
        " (#{parent["description"]})".green
    end

    # -----------------------------------------------
    # Ops

    # TxCores::program1(core)
    def self.program1(core)
        loop {

            core = Catalyst::itemOrNull(core["uuid"])
            return if core.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(core, false)
            puts  Listing::toString2(store, core)
            puts  ""

            TxCores::childrenInOrder(core)
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
                Updates::itemAttributeUpdate(task["uuid"], "coreX-2137", core["uuid"])
                next
            end

            if input == "move" then
                Catalyst::selectSubsetAndMoveToSelectedCore(TxCores::childrenInOrder())
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # TxCores::interactivelySelectAndPutInCore(item) # boolean
    def self.interactivelySelectAndPutInCore(item)
        core = TxCores::interactivelySelectOneOrNull()
        return false if core.nil?
        Updates::itemAttributeUpdate(item["uuid"], "coreX-2137", core["uuid"])
        true
    end
end
