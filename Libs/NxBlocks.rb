
class NxBlocks

    # NxBlocks::issueWithInit(uuid, description, engine)
    def self.issueWithInit(uuid, description, engine)
        Cubes2::itemInit(uuid, "NxBlock")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "engine-0020", engine)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # NxBlocks::interactivelyIssueNewOrNull2(uuid)
    def self.interactivelyIssueNewOrNull2(uuid)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        core = TxCores::interactivelyMakeNewOrNull()
        return if core.nil?
        NxBlocks::issueWithInit(uuid, description, core)
    end

    # NxBlocks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        NxBlocks::interactivelyIssueNewOrNull2(uuid)
    end

    # ------------------
    # Data

    # NxBlocks::bufferInCardinal()
    def self.bufferInCardinal()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Buffer-In")
            .select{|location| !File.basename(location).start_with?(".") }
            .size
    end

    # NxBlocks::toString(item, context = nil)
    def self.toString(item, context = nil)
        icon = NxBlocks::isTopBlock(item) ? "🔺" : "🔸"
        if item["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            if NxBlocks::bufferInCardinal() > 0 then
                return "#{icon}#{TxCores::suffix1(item["engine-0020"], context)} orphaned tasks (automatic); special circumstances: DataHub/Buffer-In"
            end
        end
        
        "#{icon}#{TxCores::suffix1(item["engine-0020"], context)} #{item["description"]}"
    end

    # NxBlocks::metric(item, indx)
    def self.metric(item, indx)
        core = item["engine-0020"]
        if core["type"] == "blocking-until-done" then
            return 0.75 + 0.01 * 1.to_f/(indx+1)
        end
        0.30 + 0.20 * 1.to_f/(indx+1)
    end

    # NxBlocks::recursiveDescent(blocks)
    def self.recursiveDescent(blocks)
        blocks
            .map{|block| NxBlocks::elementsInNaturalCruiseOrder(block).select{|i| i["mikuType"] == "NxBlock" }.sort_by{|item| NxBlocks::dayCompletionRatio(item) } + [block]}
            .flatten
    end

    # NxBlocks::isTopBlock(item)
    def self.isTopBlock(item)
        item["parentuuid-0032"].nil? or Cubes2::itemOrNull(item["parentuuid-0032"]).nil? 
    end

    # NxBlocks::topBlocks()
    def self.topBlocks()
        Cubes2::mikuType("NxBlock")
            .select{|item| NxBlocks::isTopBlock(item) }
    end

    # NxBlocks::blocksInRecursiveDescent()
    def self.blocksInRecursiveDescent()
        topBlocks = NxBlocks::topBlocks()
                    .sort_by{|item| NxBlocks::dayCompletionRatio(item) }
        NxBlocks::recursiveDescent(topBlocks)
    end

    # NxBlocks::listingItems()
    def self.listingItems()
        NxBlocks::blocksInRecursiveDescent()
            .select{|block| NxBlocks::dayCompletionRatio(block) < 1 }
            .sort_by{|block| NxBlocks::dayCompletionRatio(block) }
    end

    # NxBlocks::elementsInNaturalCruiseOrder(cruiser)
    def self.elementsInNaturalCruiseOrder(cruiser)
        if cruiser["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            if NxBlocks::bufferInCardinal() > 0 then
                return []
            end
            return Cubes2::mikuType("NxTask")
                    .select{|item| NxTasks::isOrphan(item) }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        if cruiser["uuid"] == "1c699298-c26c-47d9-806b-e19f84fd5d75" then # waves !interruption (automatic)
            return Waves::listingItems().select{|item| !item["interruption"] }
        end
        if cruiser["uuid"] == "ba25c5c4-4a7c-47f3-ab9f-8ca04793bd34" then # missions (automatic)
            return Cubes2::mikuType("NxMission").sort_by{|item| item["lastDoneUnixtime"] }
        end
        Cubes2::items()
            .select{|item| item["parentuuid-0032"] == cruiser["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxBlocks::elementsForPrefix(cruiser)
    def self.elementsForPrefix(cruiser)
        if cruiser["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            return Cubes2::mikuType("NxTask")
                    .select{|item| NxTasks::isOrphan(item) }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        if cruiser["uuid"] == "1c699298-c26c-47d9-806b-e19f84fd5d75" then # waves !interruption (automatic)
            return Waves::listingItems().select{|item| !item["interruption"] }
        end

        items = Cubes2::items()
                .select{|item| item["parentuuid-0032"] == cruiser["uuid"] }

        i1, i2 = items.partition{|item| item["mikuType"] == "NxBlock" }
        i1.select{|item| NxBlocks::dayCompletionRatio(item) < 1 }.sort_by{|item| NxBlocks::dayCompletionRatio(item) } + i2.sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxBlocks::interactivelySelectOneTopBlockOrNull()
    def self.interactivelySelectOneTopBlockOrNull()
        topBlocks = NxBlocks::topBlocks()
                    .sort_by{|item| NxBlocks::dayCompletionRatio(item) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("block", topBlocks, lambda{|item| NxBlocks::toString(item) })
    end

    # NxBlocks::interactivelySelectBlockUsingTopDownNavigationOrNull(block = nil)
    def self.interactivelySelectBlockUsingTopDownNavigationOrNull(block = nil)
        if block.nil? then
            block = NxBlocks::interactivelySelectOneTopBlockOrNull()
            return nil if block.nil?
            return NxBlocks::interactivelySelectBlockUsingTopDownNavigationOrNull(block)
        end
        childrenblocks = NxBlocks::elementsInNaturalCruiseOrder(block).select{|item| item["mikuType"] == "NxBlock" }.sort_by{|item| NxBlocks::dayCompletionRatio(item) }
        if childrenblocks.empty? then
            return block
        end
        selected = LucilleCore::selectEntityFromListOfEntitiesOrNull("block", [block] + childrenblocks, lambda{|item| NxBlocks::toString(item) })
        return if selected.nil?
        if selected["uuid"] == block["uuid"] then
            return selected
        end
        NxBlocks::interactivelySelectBlockUsingTopDownNavigationOrNull(selected)
    end

    # NxBlocks::selectZeroOrMore()
    def self.selectZeroOrMore()
        items = Cubes2::mikuType("NxBlock")
                    .sort_by{|item| NxBlocks::dayCompletionRatio(item) }
        selected, _ = LucilleCore::selectZeroOrMore("item", [], items, lambda{|item| NxBlocks::toString(item) })
        selected
    end

    # NxBlocks::selectSubsetAndMoveToSelectedBlock(items)
    def self.selectSubsetAndMoveToSelectedBlock(items)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        block = NxBlocks::interactivelySelectBlockUsingTopDownNavigationOrNull()
        return if block.nil?
        selected.each{|item|
            Cubes2::setAttribute(item["uuid"], "parentuuid-0032", block["uuid"])
        }
    end

    # NxBlocks::topPosition(item)
    def self.topPosition(item)
        ([0] + NxBlocks::elementsInNaturalCruiseOrder(item).map{|task| task["global-positioning"] || 0 }).min
    end

    # NxBlocks::dayCompletionRatio(item)
    def self.dayCompletionRatio(item)
        TxCores::coreDayCompletionRatio(item["engine-0020"])
    end

    # ------------------
    # Ops

    # NxBlocks::interactivelySelectBlockAndAddTo(itemuuid)
    def self.interactivelySelectBlockAndAddTo(itemuuid)
        block = NxBlocks::interactivelySelectBlockUsingTopDownNavigationOrNull()
        return if block.nil?
        Cubes2::setAttribute(itemuuid, "parentuuid-0032", block["uuid"])
    end

    # NxBlocks::access(item)
    def self.access(item)
        NxBlocks::program1(item)
    end

    # NxBlocks::natural(item)
    def self.natural(item)
        NxBlocks::program1(item)
    end

    # NxBlocks::pile(item)
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
                Cubes2::setAttribute(task["uuid"], "global-positioning", NxBlocks::topPosition(item) - 1)
            }
    end

    # NxBlocks::program1(item)
    def self.program1(item)
        loop {

            item = Cubes2::itemOrNull(item["uuid"])
            return if item.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(item, false)
            puts  Listing::toString2(store, item)
            puts  ""

            Prefix::prefix(NxBlocks::elementsInNaturalCruiseOrder(item))
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString3(store, item)
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
                block = NxBlocks::interactivelyIssueNewOrNull()
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
                Cubes2::setAttribute(task["uuid"], "global-positioning", NxBlocks::topPosition(item) - 1)
                next
            end

            if input == "pile" then
                NxBlocks::pile(item)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("item", [], NxBlocks::elementsInNaturalCruiseOrder(item), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes2::setAttribute(i["uuid"], "global-positioning", NxBlocks::topPosition(item) - 1)
                }
                next
            end

            if input == "move" then
                NxBlocks::selectSubsetAndMoveToSelectedBlock(NxBlocks::elementsInNaturalCruiseOrder(item))
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxBlocks::program2()
    def self.program2()
        loop {

            items = NxBlocks::topBlocks()
                        .sort_by{|item| NxBlocks::dayCompletionRatio(item) }
            return if items.empty?

            system("clear")

            store = ItemStore.new()

            puts  ""

            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input.start_with?("..") then
                indx = input[2, 9].strip.to_i
                item = store.get(indx)
                next if item.nil?
                NxBlocks::program1(item)
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxBlocks::done(item)
    def self.done(item)
        DoNotShowUntil2::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()))
    end
end
