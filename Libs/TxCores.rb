
class TxCores

    # -----------------------------------------------
    # Build

    # TxCores::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        engine = TxEngines::interactivelyMakeNewOrNull()

        uuid = SecureRandom.uuid
        DataCenter::itemInit(uuid, "TxCore")

        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "engine-0916", engine)

        DataCenter::itemOrNull(uuid)
    end

    # -----------------------------------------------
    # Data

    # TxCores::toString(item)
    def self.toString(item)
        padding = XCache::getOrDefaultValue("b1bd5d84-2051-432a-83d1-62ece0bf54f7", "0").to_i
        "⏱️ #{TxEngines::string1(item).green} #{item["description"].ljust(padding)}"
    end

    # TxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        cores = DataCenter::mikuType("TxCore")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|item| PolyFunctions::toString(item) })
    end

    # TxCores::listingItems()
    def self.listingItems()
        DataCenter::mikuType("TxCore")
    end

    # TxCores::children(core)
    def self.children(core)
        DataCenter::mikuType("NxTask")
                .select{|item| item["coreX-2137"] == core["uuid"] }
    end

    # TxCores::childrenInGlobalPositioningOrder(core)
    def self.childrenInGlobalPositioningOrder(core)
        if core["uuid"] == "3d4a56c7-0215-4298-bd05-086113947dd2" then
            # In the case of "Perfection" we return this:
            return TxCores::children(core).sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
        end
        TxCores::children(core).sort_by{|item| item["global-positioning"] || 0 }
    end

    # TxCores::suffix(item)
    def self.suffix(item)
        return "" if item["coreX-2137"].nil?
        parent = DataCenter::itemOrNull(item["coreX-2137"])
        return "" if parent.nil?
        " (#{parent["description"]})".green
    end

    # TxCores::topPositionInCore(core)
    def self.topPositionInCore(core)
        TxCores::childrenInGlobalPositioningOrder(core)
            .reduce(0){|topPosition, item|
                [topPosition, item["global-positioning"] || 0].min
            }
    end

    # TxCores::lastPositionInCore(core)
    def self.lastPositionInCore(core)
        TxCores::childrenInGlobalPositioningOrder(core)
            .reduce(0){|topPosition, item|
                [topPosition, item["global-positioning"] || 0].max
            }
    end

    # TxCores::interactivelySelectPositionInCore(core)
    def self.interactivelySelectPositionInCore(core)
        if core["uuid"] == "3d4a56c7-0215-4298-bd05-086113947dd2" then
            # In the case of "Perfection" we return this:
            return rand
        end
        puts 
        TxCores::childrenInGlobalPositioningOrder(core).first(20).each{|task|
            puts "- #{TxCores::toString(task)}"
        }
        input = LucilleCore::askQuestionAnswerAsString("top (default) | next | position")
        if input == "" then
            return TxCores::topPositionInCore(core) - 1
        end
        if input == "top" then
            return TxCores::topPositionInCore(core) - 1
        end
        if input == "last" then
            return TxCores::lastPositionInCore(core) + 1
        end
        input.to_f
    end

    # -----------------------------------------------
    # Ops

    # TxCores::program1(core)
    def self.program1(core)
        loop {

            core = DataCenter::itemOrNull(core["uuid"])
            return if core.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(core, false)
            puts  Listing::toString2(store, core)
            puts  ""

            children = Prefix::prefix(TxCores::childrenInGlobalPositioningOrder(core))
            children
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            puts "task | pile (*) | sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                DataCenter::setAttribute(task["uuid"], "coreX-2137", core["uuid"])
                next
            end

            if input == "pile" then
                text = CommonUtils::editTextSynchronously("").strip
                next if text == ""
                topPosition = children
                                .reduce(0){|topPosition, item|
                                    [topPosition, item["global-positioning"] || 0].min
                                }
                text
                    .lines
                    .map{|line| line.strip }
                    .reverse
                    .each{|line|
                        task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                        puts JSON.pretty_generate(task)
                        DataCenter::setAttribute(task["uuid"], "coreX-2137", core["uuid"])
                        topPosition = topPosition - 1
                        DataCenter::setAttribute(task["uuid"], "global-positioning", topPosition)
                    }
                next
            end

            if input.start_with?("pile") then
                position = input[4, input.size].strip
                next if position == ""
                position = position.to_i
                if position == 1 then
                    text = CommonUtils::editTextSynchronously("").strip
                    next if text == ""
                    topPosition = children
                                    .reduce(0){|topPosition, item|
                                        [topPosition, item["global-positioning"] || 0].min
                                    }
                    text
                        .lines
                        .map{|line| line.strip }
                        .reverse
                        .each{|line|
                            task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                            puts JSON.pretty_generate(task)
                            DataCenter::setAttribute(task["uuid"], "coreX-2137", core["uuid"])
                            topPosition = topPosition - 1
                            DataCenter::setAttribute(task["uuid"], "global-positioning", topPosition)
                        }
                else
                    next if children.empty?
                    puts JSON.pretty_generate(children[position-1])
                    NxStrats::interactivelyPile(children[position-1])
                end
                next
            end

            if input == "sort" then
                topPosition = children
                                .reduce(0){|topPosition, item|
                                    [topPosition, item["global-positioning"] || 0].min
                                }
                children = children
                selected, _ = LucilleCore::selectZeroOrMore("item", [], children, lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    topPosition = topPosition - 1
                    DataCenter::setAttribute(item["uuid"], "global-positioning", topPosition)
                }
                next
            end

            if input == "move" then
                Catalyst::selectSubsetAndMoveToSelectedCore(TxCores::childrenInGlobalPositioningOrder())
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # TxCores::interactivelySelectAAndPutInCore(item) # boolean
    def self.interactivelySelectAAndPutInCore(item)
        core = TxCores::interactivelySelectOneOrNull()
        return false if core.nil?
        DataCenter::setAttribute(item["uuid"], "coreX-2137", core["uuid"])
        position = TxCores::interactivelySelectPositionInCore(core)
        DataCenter::setAttribute(task["uuid"], "global-positioning", position)
        true
    end
end
