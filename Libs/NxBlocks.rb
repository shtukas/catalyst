
class NxBlocks

    # NxBlocks::issueWithInit(uuid, description, engine)
    def self.issueWithInit(uuid, description, engine)
        Cubes::itemInit(uuid, "NxBlock")
        Cubes::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute(uuid, "engine-0020", engine)
        Cubes::setAttribute(uuid, "description", description)
        CacheWS::emit("mikutype-has-been-modified:NxBlock")
        Cubes::itemOrNull(uuid)
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

    # NxBlocks::toString(item, context = nil)
    def self.toString(item, context = nil)
        icon = NxBlocks::isTopBlock(item) ? "⛵️" : "🔺"
        if item["uuid"] == "60949c4f-4e1f-45d3-acb4-3b6c718ac1ed" then # orphaned tasks (automatic)
            count = LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataHub/Buffer-In").select{|location| !File.basename(location).start_with?(".") }
            if count then
                return "#{icon}#{TxCores::suffix1(item["engine-0020"], context)} special circumstances: DataHub/Buffer-In"
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
        if core["type"] == "booster" then
            ratio = TxCores::coreDayCompletionRatio(core)
            if ratio >= 1 then
                return 0.1
            end
            return 0.60 + 0.10 * (1-ratio)
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
        item["parentuuid-0032"].nil? or Cubes::itemOrNull(item["parentuuid-0032"]).nil? 
    end

    # NxBlocks::topBlocks()
    def self.topBlocks()
        Cubes::mikuType("NxBlock")
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
        items0 = (lambda {
            items = CacheWS::getOrNull("47FDDD68-0655-494E-996C-350BE8654807")
            return items if items
            items = Cubes::mikuType("NxBlock")
                        .select{|block| block["engine-0020"]["type"] == "booster" }
                        .select{|block| block["engine-0020"]["endunixtime"] <= Time.new.to_i } # expired boosters

            signals = items.map{|item| "item-has-been-modified:#{item["uuid"]}" }
            CacheWS::set("47FDDD68-0655-494E-996C-350BE8654807", items, signals)
            items
        }).call()

        items1 = (lambda {
            items = CacheWS::getOrNull("8EF6CD96-72CF-45CB-956C-DF2B510CA8A1")
            return items if items
            items = Cubes::mikuType("NxBlock")
                        .select{|block| block["engine-0020"]["type"] == "booster" }
                        .select{|block| NxBlocks::dayCompletionRatio(block) < 1 }
                        .sort_by{|block| NxBlocks::dayCompletionRatio(block) }
            signals = items.map{|item| "item-has-been-modified:#{item["uuid"]}" }
            CacheWS::set("8EF6CD96-72CF-45CB-956C-DF2B510CA8A1", items, signals)
            items
        }).call()

        items2 = (lambda {
            items = CacheWS::getOrNull("36E64A0A-D4DD-4AF7-B9ED-303602E57781")
            return items if items

            items = NxBlocks::blocksInRecursiveDescent()
                .select{|block| NxBlocks::dayCompletionRatio(block) < 1 }
                .sort_by{|block| NxBlocks::dayCompletionRatio(block) }

            signals = items.map{|item| "item-has-been-modified:#{item["uuid"]}" }
            CacheWS::set("36E64A0A-D4DD-4AF7-B9ED-303602E57781", items, signals)
            items
        }).call()

        items0 + items1 + items2
    end

    # NxBlocks::elementsInNaturalCruiseOrder(cruiser)
    def self.elementsInNaturalCruiseOrder(cruiser)
        if cruiser["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            return Cubes::mikuType("NxTask")
                    .select{|item| NxTasks::isOrphan(item) }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        if cruiser["uuid"] == "1c699298-c26c-47d9-806b-e19f84fd5d75" then # waves !interruption (automatic)
            return Waves::listingItems().select{|item| !item["interruption"] }
        end
        if cruiser["description"].include?("patrol") then
            elements = Cubes::items()
                        .select{|item| item["parentuuid-0032"] == cruiser["uuid"] }
            return elements.sort_by{|i| i["unixtime"] }
        end

        Cubes::items()
            .select{|item| item["parentuuid-0032"] == cruiser["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxBlocks::elementsForPrefix(cruiser)
    def self.elementsForPrefix(cruiser)
        if cruiser["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            return Cubes::mikuType("NxTask")
                    .select{|item| NxTasks::isOrphan(item) }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        if cruiser["uuid"] == "1c699298-c26c-47d9-806b-e19f84fd5d75" then # waves !interruption (automatic)
            return Waves::listingItems().select{|item| !item["interruption"] }
        end

        items = Cubes::items()
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
        items = Cubes::mikuType("NxBlock")
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
            Cubes::setAttribute(item["uuid"], "parentuuid-0032", block["uuid"])
        }
    end

    # NxBlocks::topPosition(item)
    def self.topPosition(item)
        ([0] + NxBlocks::elementsInNaturalCruiseOrder(item).map{|task| task["global-positioning"] || 0 }).min
    end

    # NxBlocks::dayCompletionRatio(item)
    def self.dayCompletionRatio(item)
        if item["engine-0020"]["type"] == "content-driven" then
            count = NxBlocks::elementsInNaturalCruiseOrder(item).count
            return 1 if count == 0
            return 0.9*(1.to_f/count)
        end
        TxCores::coreDayCompletionRatio(item["engine-0020"])
    end

    # ------------------
    # Ops

    # NxBlocks::interactivelySelectBlockAndAddTo(itemuuid)
    def self.interactivelySelectBlockAndAddTo(itemuuid)
        block = NxBlocks::interactivelySelectBlockUsingTopDownNavigationOrNull()
        return if block.nil?
        Cubes::setAttribute(itemuuid, "parentuuid-0032", block["uuid"])
    end

    # NxBlocks::access(item)
    def self.access(item)
        if item["todotextfile-1312"] then
            # this takes priority
            todotextfile = item["todotextfile-1312"]
            location = Catalyst::selectTodoTextFileLocationOrNull(todotextfile)
            if location.nil? then
                puts "Could not resolve this todotextfile: #{todotextfile}"
                if LucilleCore::askQuestionAnswerAsBoolean("remove reference from item ?") then
                    Cubes::setAttribute(item["uuid"], "todotextfile-1312", nil)
                end
                return
            end
            puts "found: #{location}"
            system("open '#{location}'")
            return
        end

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
                Cubes::setAttribute(task["uuid"], "parentuuid-0032", item["uuid"])
                Cubes::setAttribute(task["uuid"], "global-positioning", NxBlocks::topPosition(item) - 1)
            }
    end

    # NxBlocks::program1(item)
    def self.program1(item)
        loop {

            item = Cubes::itemOrNull(item["uuid"])
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

            puts "top | pile | task | patrol | block | sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes::setAttribute(task["uuid"], "parentuuid-0032", item["uuid"])
                next
            end

            if input == "patrol" then
                patrol = NxPatrols::interactivelyIssueNewOrNull()
                next if patrol.nil?
                puts JSON.pretty_generate(patrol)
                Cubes::setAttribute(patrol["uuid"], "parentuuid-0032", item["uuid"])
                next
            end

            if input == "block" then
                block = NxBlocks::interactivelyIssueNewOrNull()
                next if block.nil?
                puts JSON.pretty_generate(block)
                Cubes::setAttribute(block["uuid"], "parentuuid-0032", item["uuid"])
                next
            end

            if input == "top" then
                line = LucilleCore::askQuestionAnswerAsString("description: ")
                next if line == ""
                task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                Cubes::setAttribute(task["uuid"], "parentuuid-0032", item["uuid"])
                Cubes::setAttribute(task["uuid"], "global-positioning", NxBlocks::topPosition(item) - 1)
                next
            end

            if input == "pile" then
                NxBlocks::pile(item)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("item", [], NxBlocks::elementsInNaturalCruiseOrder(item), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes::setAttribute(i["uuid"], "global-positioning", NxBlocks::topPosition(item) - 1)
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
        DoNotShowUntil::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()))
    end
end
