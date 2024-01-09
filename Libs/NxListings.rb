
class NxListings

    # NxListings::issueWithInit(uuid, description, engine)
    def self.issueWithInit(uuid, description, engine)
        Cubes2::itemInit(uuid, "NxListing")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "engine-0020", engine)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # NxListings::interactivelyIssueNewOrNull2(uuid)
    def self.interactivelyIssueNewOrNull2(uuid)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        core = TxCores::interactivelyMakeNewOrNull()
        return if core.nil?
        NxListings::issueWithInit(uuid, description, core)
    end

    # NxListings::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        NxListings::interactivelyIssueNewOrNull2(uuid)
    end

    # ------------------
    # Data

    # NxListings::bufferInCardinal()
    def self.bufferInCardinal()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Buffer-In")
            .select{|location| !File.basename(location).start_with?(".") }
            .size
    end

    # NxListings::icon(item)
    def self.icon(item)
        if item["special-circumstances-bottom-task-1939"] then
            return "🔥"
        end
        NxListings::isRootListing(item) ? "🔺" : "🔸"
    end

    # NxListings::toString(item, context = nil)
    def self.toString(item, context = nil)
        icon = NxListings::icon(item)
        if item["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            if NxListings::bufferInCardinal() > 0 then
                return "#{icon}#{TxCores::suffix1(item["engine-0020"], context)} orphaned tasks (automatic); special circumstances: DataHub/Buffer-In"
            end
        end
        "#{icon}#{TxCores::suffix1(item["engine-0020"], context)} #{item["description"]}"
    end

    # NxListings::metric(item, indx)
    def self.metric(item, indx)
        core = item["engine-0020"]
        if core["type"] == "blocking-until-done" then
            return 0.75 + 0.01 * 1.to_f/(indx+1)
        end
        0.30 + 0.20 * 1.to_f/(indx+1)
    end

    # NxListings::recursiveDescent(blocks)
    def self.recursiveDescent(blocks)
        blocks
            .map{|block| NxListings::elementsInNaturalOrder(block).select{|i| i["mikuType"] == "NxListing" }.sort_by{|item| NxListings::dayCompletionRatio(item) } + [block]}
            .flatten
    end

    # NxListings::isRootListing(item)
    def self.isRootListing(item)
        item["parentuuid-0032"].nil? or Cubes2::itemOrNull(item["parentuuid-0032"]).nil? 
    end

    # NxListings::topBlocks()
    def self.topBlocks()
        Cubes2::mikuType("NxListing")
            .select{|item| NxListings::isRootListing(item) }
    end

    # NxListings::listingsInRecursiveDescent()
    def self.listingsInRecursiveDescent()
        topBlocks = NxListings::topBlocks()
                    .sort_by{|item| NxListings::dayCompletionRatio(item) }
        NxListings::recursiveDescent(daylies + topBlocks)
    end

    # NxListings::muiItems()
    def self.muiItems()
        NxListings::listingsInRecursiveDescent()
            .select{|block| NxListings::dayCompletionRatio(block) < 1 }
            .sort_by{|block| NxListings::dayCompletionRatio(block) }
    end

    # NxListings::elementsInNaturalOrder(listing)
    def self.elementsInNaturalOrder(listing)
        if listing["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            if NxListings::bufferInCardinal() > 0 then
                return []
            end
            return Cubes2::mikuType("NxTask")
                    .select{|item| NxTasks::isOrphan(item) }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        if listing["uuid"] == "1c699298-c26c-47d9-806b-e19f84fd5d75" then # waves !interruption (automatic)
            return Waves::muiItems().select{|item| !item["interruption"] }
        end
        if listing["uuid"] == "ba25c5c4-4a7c-47f3-ab9f-8ca04793bd34" then # missions (automatic)
            return Cubes2::mikuType("NxMission").sort_by{|item| item["lastDoneUnixtime"] }
        end
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == listing["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxListings::elementsForPrefix(listing)
    def self.elementsForPrefix(listing)
        if listing["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            return Cubes2::mikuType("NxTask")
                    .select{|item| NxTasks::isOrphan(item) }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        if listing["uuid"] == "1c699298-c26c-47d9-806b-e19f84fd5d75" then # waves !interruption (automatic)
            return Waves::muiItems().select{|item| !item["interruption"] }
        end

        items = Cubes2::items()
                .select{|item| item["parentuuid-0032"] == listing["uuid"] }

        i1, i2 = items.partition{|item| item["mikuType"] == "NxListing" }
        i1.select{|item| NxListings::dayCompletionRatio(item) < 1 }.sort_by{|item| NxListings::dayCompletionRatio(item) } + i2.sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxListings::interactivelySelectOneTopBlockOrNull()
    def self.interactivelySelectOneTopBlockOrNull()
        topBlocks = NxListings::topBlocks()
                    .sort_by{|item| NxListings::dayCompletionRatio(item) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("block", topBlocks, lambda{|item| NxListings::toString(item) })
    end

    # NxListings::interactivelySelectOneUsingTopDownNavigationOrNull(block = nil)
    def self.interactivelySelectOneUsingTopDownNavigationOrNull(block = nil)
        if block.nil? then
            block = NxListings::interactivelySelectOneTopBlockOrNull()
            return nil if block.nil?
            return NxListings::interactivelySelectOneUsingTopDownNavigationOrNull(block)
        end
        childrenblocks = NxListings::elementsInNaturalOrder(block).select{|item| item["mikuType"] == "NxListing" }.sort_by{|item| NxListings::dayCompletionRatio(item) }
        if childrenblocks.empty? then
            return block
        end
        selected = LucilleCore::selectEntityFromListOfEntitiesOrNull("block", [block] + childrenblocks, lambda{|item| NxListings::toString(item) })
        return if selected.nil?
        if selected["uuid"] == block["uuid"] then
            return selected
        end
        NxListings::interactivelySelectOneUsingTopDownNavigationOrNull(selected)
    end

    # NxListings::selectZeroOrMore()
    def self.selectZeroOrMore()
        items = Cubes2::mikuType("NxListing")
                    .sort_by{|item| NxListings::dayCompletionRatio(item) }
        selected, _ = LucilleCore::selectZeroOrMore("item", [], items, lambda{|item| NxListings::toString(item) })
        selected
    end

    # NxListings::selectSubsetOfItemsAndMove(items)
    def self.selectSubsetOfItemsAndMove(items)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        block = NxListings::interactivelySelectOneUsingTopDownNavigationOrNull()
        return if block.nil?
        selected.each{|item|
            Cubes2::setAttribute(item["uuid"], "parentuuid-0032", block["uuid"])
        }
    end

    # NxListings::topPosition(item)
    def self.topPosition(item)
        ([0] + NxListings::elementsInNaturalOrder(item).map{|task| task["global-positioning"] || 0 }).min
    end

    # NxListings::dayCompletionRatio(item)
    def self.dayCompletionRatio(item)
        TxCores::coreDayCompletionRatio(item["engine-0020"])
    end

    # NxListings::toString3(store, item)
    def self.toString3(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "
        global_positioning = "[#{"%7.3f" % (item["global-positioning"] || 0)}]"
        line = "#{storePrefix}#{global_positioning}#{TxCores::suffix2(item)} #{PolyFunctions::toString(item, "listing")}#{TxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil2::suffixString(item)}#{Catalyst::donationSuffix(item)}#{NxStrats::suffix(item)}"

        if !DoNotShowUntil2::isVisible(item) and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        line
    end

    # NxListings::interactivelySelectPositionOrNull(listing)
    def self.interactivelySelectPositionOrNull(listing)
        elements = NxListings::elementsInNaturalOrder(listing)
        elements.first(20).each{|item|
            puts "#{NxListings::toString3(nil, item)}"
        }
        position = LucilleCore::askQuestionAnswerAsString("position (first, next, <position>): ")
        if position == "first" then
            return ([0] + elements.map{|item| item["global-positioning"] || 0 }).min - 1
        end
        if position == "next" then
            return ([0] + elements.map{|item| item["global-positioning"] || 0 }).max + 1
        end
        position = position.to_f
        position
    end

    # ------------------
    # Ops

    # NxListings::interactivelySelectOneAndAddTo(itemuuid)
    def self.interactivelySelectOneAndAddTo(itemuuid)
        listing = NxListings::interactivelySelectOneUsingTopDownNavigationOrNull()
        return if listing.nil?
        Cubes2::setAttribute(itemuuid, "parentuuid-0032", listing["uuid"])
        position = NxListings::interactivelySelectPositionOrNull(listing)
        if position then
            Cubes2::setAttribute(itemuuid, "global-positioning", position)
        end
    end

    # NxListings::access(item)
    def self.access(item)
        NxListings::program1(item)
    end

    # NxListings::natural(item)
    def self.natural(item)
        NxListings::program1(item)
    end

    # NxListings::pile(item)
    def self.pile(item)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", item["uuid"])
                Cubes2::setAttribute(task["uuid"], "global-positioning", NxListings::topPosition(item) - 1)
            }
    end

    # NxListings::program1(item)
    def self.program1(item)
        loop {

            item = Cubes2::itemOrNull(item["uuid"])
            return if item.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(item, false)
            puts  MainUserInterface::toString2(store, item)
            puts  ""

            NxListings::elementsInNaturalOrder(item)
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts  NxListings::toString3(store, item)
                }

            puts ""

            puts "top | pile | task | mission | block | sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", item["uuid"])
                next
            end

            if input == "mission" then
                mission = NxMissions::interactivelyIssueNewOrNull()
                next if mission.nil?
                puts JSON.pretty_generate(mission)
                Cubes2::setAttribute(mission["uuid"], "parentuuid-0032", item["uuid"])
                next
            end

            if input == "block" then
                block = NxListings::interactivelyIssueNewOrNull()
                next if block.nil?
                puts JSON.pretty_generate(block)
                Cubes2::setAttribute(block["uuid"], "parentuuid-0032", item["uuid"])
                next
            end

            if input == "top" then
                line = LucilleCore::askQuestionAnswerAsString("description: ")
                next if line == ""
                task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                Cubes2::setAttribute(task["uuid"], "parentuuid-0032", item["uuid"])
                Cubes2::setAttribute(task["uuid"], "global-positioning", NxListings::topPosition(item) - 1)
                next
            end

            if input == "pile" then
                NxListings::pile(item)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("item", [], NxListings::elementsInNaturalOrder(item), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxListings::topPosition(item) - 1)
                }
                next
            end

            if input == "move" then
                NxListings::selectSubsetOfItemsAndMove(NxListings::elementsInNaturalOrder(item))
                next
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxListings::program2()
    def self.program2()
        loop {

            items = NxListings::topBlocks()
                        .sort_by{|item| NxListings::dayCompletionRatio(item) }
            return if items.empty?

            system("clear")

            store = ItemStore.new()

            puts  ""

            items
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts  MainUserInterface::toString2(store, item)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input.start_with?("..") then
                indx = input[2, 9].strip.to_i
                item = store.get(indx)
                next if item.nil?
                NxListings::program1(item)
            end

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxListings::done(item)
    def self.done(item)
        DoNotShowUntil2::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()))
    end
end
