# encoding: UTF-8

class SpaceControl

    def initialize(remaining_vertical_space)
        @remaining_vertical_space = remaining_vertical_space
    end

    def putsline(line)
        vspace = CommonUtils::verticalSize(line)
        return if vspace > @remaining_vertical_space
        puts line
        @remaining_vertical_space = @remaining_vertical_space - vspace
    end
end

class Listing

    # Listing::listingCommands()
    def self.listingCommands()
        [
            "[all] .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | landing (<n>) | expose (<n>) | park (<n>) | add time <n> | board (<n>) | unboard <n> | note (<n>) | coredata <n> | destroy <n>",
            "[makers] anniversary | manual countdown | wave | today | tomorrow | ondate | desktop | first task | task | fire | project | float",
            "[makers] drop",
            "[transmutation] recast (<n>)",
            "[positioning] priority <n> <position> | priority line | priority set position <n> <position> | unpick <n>",
            "[divings] anniversaries | ondates | waves | todos | desktop | boards | time promises",
            "[NxBalls] start | start * | stop | stop * | pause | pursue",
            "[NxOndate] redate",
            "[NxBoard] holiday <n>",
            "[misc] search | speed | commands | mikuTypes | edit object <uuid>",
        ].join("\n")
    end

    # Listing::listingCommandInterpreter(input, store, board or nil)
    def self.listingCommandInterpreter(input, store, board)

        if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
            if (item = store.getDefault()) then
                DoNotShowUntil::setUnixtime(item, unixtime)
                return
            end
        end

        if Interpreting::match("..", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::doubleDot(item)
            return
        end

        if Interpreting::match(".. *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::doubleDot(item)
            return
        end

        if Interpreting::match("park", input) then
            item = store.getDefault()
            return if item.nil?
            item["parking"] = Time.new.to_i
            N3Objects::commit(item)
            return
        end


        if Interpreting::match("park *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            item["parking"] = Time.new.to_i
            N3Objects::commit(item)
        end

        if Interpreting::match("add time *", input) then
            _, _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
            PolyActions::addTimeToItem(item, timeInHours*3600)
        end

        if Interpreting::match("access", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("access *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("anniversary", input) then
            Anniversaries::issueNewAnniversaryOrNullInteractively()
            return
        end

        if Interpreting::match("anniversaries", input) then
            Anniversaries::dive()
            return
        end

        if Interpreting::match("board", input) then
            item = store.getDefault()
            return if item.nil?
            BoardsAndItems::askAndMaybeAttach(item)
            return
        end

        if Interpreting::match("board *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            BoardsAndItems::askAndMaybeAttach(item)
            return
        end

        if Interpreting::match("boards", input) then
            NxBoards::boards()
            return
        end

        if Interpreting::match("unboard *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            item["boarduuid"] = nil
            N3Objects::commit(item)
            return
        end

        if Interpreting::match("time promises", input) then
            NxTimePromises::show()
            return
        end

        if Interpreting::match("priority line", input) then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            nxline = NxLines::issue(line)
            item = NxListingPriorities::interactivelyIssue(nxline)
            if item["boarduuid"].nil? then
                item = BoardsAndItems::askAndMaybeAttach(item)
            end
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("priority set position * *", input) then
            _, _, _, ordinal, position = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            position = position.to_f
            item["position"] = position
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
            return
        end

        if Interpreting::match("priority * *", input) then
            _, ordinal, position = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            return if item["mikuType"] == "NxListingPriority"
            item = NxListingPriorities::interactivelyIssue(item, position.to_f)
            puts JSON.pretty_generate(item)
            BoardsAndItems::askAndMaybeAttach(item)
            return
        end

        if Interpreting::match("coredata *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            reference =  CoreData::interactivelyMakeNewReferenceStringOrNull(item["uuid"])
            return if reference.nil?
            item["field11"] = reference
            N3Objects::commit(item)
            return
        end

        if Interpreting::match("unpick *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            if item["mikuType"] != "NxListingPriority" then
                puts "The unpick command is only for NxListingPriority items"
                LucilleCore::pressEnterToContinue()
                return
            end
            NxListingPriorities::destroy(item["uuid"])
            return
        end

        if Interpreting::match("commands", input) then
            puts Listing::listingCommands().yellow
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("description", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::editDescription(item)
            return
        end

        if Interpreting::match("description *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::editDescription(item)
            return
        end

        if Interpreting::match("desktop", input) then
            system("open '#{Desktop::filepath()}'")
            return
        end

        if Interpreting::match("done", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::done(item)
            return
        end

        if Interpreting::match("done *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::done(item)
            return
        end

        if Interpreting::match("destroy *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::destroy(item)
            return
        end

        if Interpreting::match("do not show until *", input) then
            _, _, _, _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            if item["parking"] then
                item["parking"] = nil
                N3Objects::commit(item)
            end
            DoNotShowUntil::setUnixtime(item, unixtime)
            return
        end

        if Interpreting::match("exit", input) then
            exit
        end

        if Interpreting::match("expose", input) then
            item = store.getDefault()
            return if item.nil?
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("expose *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("edit object *", input) then
            _, _, uuid = Interpreting::tokenizer(input)
            object = N3Objects::getOrNull(uuid)
            object = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(object)))
            N3Objects::commit(object)
            return
        end

        if Interpreting::match("task", input) then
            item = NxTasks::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("holiday *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            if item["mikuType"] != "NxBoard" then
                puts "holiday only apply to NxBoards"
                LucilleCore::pressEnterToContinue()
                return
            end
            unixtime = CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) + 3600*3 # 3 am
            if LucilleCore::askQuestionAnswerAsBoolean("> confirm today holiday for '#{PolyFunctions::toString(item).green}': ") then
                DoNotShowUntil::setUnixtime(item, unixtime)
            end
            return
        end

        if Interpreting::match("landing", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::landing(item)
            return
        end

        if Interpreting::match("landing *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::landing(item)
            return
        end

        if Interpreting::match("mikuTypes", input) then
            puts N3Objects::getall().map{|item| item["mikuType"] }.uniq
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("manual countdown", input) then
            TxNumberTargets::issueNewOrNull()
            return
        end

        if Interpreting::match("netflix", input) then
            title = LucilleCore::askQuestionAnswerAsString("title: ")
            item = NxTasks::netflix(title)
            puts JSON.pretty_generate(item)
        end

        if Interpreting::match("note", input) then
            item = store.getDefault()
            return if item.nil?
            NxNotes::edit(item)
            return
        end

        if Interpreting::match("note *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxNotes::edit(item)
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::askAndMaybeAttach(item)
            return
        end

        if Interpreting::match("project", input) then
            item = NxProjects::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::askAndMaybeAttach(item)
            return
        end

        if Interpreting::match("projects", input) then
            NxProjects::program()
            return
        end

        if Interpreting::match("ondates", input) then
            NxOndates::report()
            return
        end

        if Interpreting::match("fire", input) then
            item = NxFires::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::askAndMaybeAttach(item)
            return
        end

        if Interpreting::match("float", input) then
            item = NxFloats::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::askAndMaybeAttach(item)
            return
        end

        if Interpreting::match("pause", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::pause(item)
            return
        end

        if Interpreting::match("pause *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBalls::pause(item)
            return
        end

        if Interpreting::match("pursue", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::pursue(item)
            return
        end

        if Interpreting::match("pursue *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::pursue(item)
            return
        end

        if Interpreting::match("first task", input) then
            item = NxTasks::priority()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::askAndMaybeAttach(item)
            return
        end

        if Interpreting::match("redate", input) then
            item = store.getDefault()
            return if item.nil?
            if item["mikuType"] != "NxOndate" then
                puts "redate is reserved for NxOndates"
                LucilleCore::pressEnterToContinue()
                return
            end
            NxOndates::redate(item)
            return
        end

        if Interpreting::match("recast", input) then
            item = store.getDefault()
            return if item.nil?
            Transmutations::transmute(item)
            return
        end

        if Interpreting::match("recast *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            Transmutations::transmute(item)
            return
        end

        if Interpreting::match("start", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::start(item)
            return
        end

        if Interpreting::match("start *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            PolyActions::start(item)
            return
        end

        if Interpreting::match("stop", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::stop(item)
            return
        end

        if Interpreting::match("stop *", input) then
            _, ordinal = Interpreting::tokenizer(input)
            item = store.get(ordinal.to_i)
            return if item.nil?
            NxBalls::stop(item)
            return
        end

        if Interpreting::match("search", input) then
            CatalystSearch::run()
            return
        end

        if Interpreting::match("speed", input) then
            Listing::speedTest()
            return
        end

        if Interpreting::match("today", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::askAndMaybeAttach(item)
            return
        end

        if Interpreting::match("tomorrow", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            item["datetime"] = "#{CommonUtils::nDaysInTheFuture(1)} 07:00:00+00:00"
            N3Objects::commit(item)
            puts JSON.pretty_generate(item)
            BoardsAndItems::askAndMaybeAttach(item)
            return
        end

        if input == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::askAndMaybeAttach(item)
            return
        end

        if input == "waves" then
            Waves::dive()
            return
        end

        if Interpreting::match("speed", input) then
            LucilleCore::pressEnterToContinue()
            return
        end
    end

    # Listing::speedTest()
    def self.speedTest()

        tests = [
            {
                "name" => "Anniversaries::listingItems()",
                "lambda" => lambda { Anniversaries::listingItems() }
            },
            {
                "name" => "NxOndates::listingItems()",
                "lambda" => lambda { NxOndates::listingItems() }
            },
            {
                "name" => "TxNumberTargets::listingItems()",
                "lambda" => lambda { TxNumberTargets::listingItems() }
            },
            {
                "name" => "NxBoards::listingItems()",
                "lambda" => lambda { NxBoards::listingItems() }
            },
            {
                "name" => "Waves::listingItemsPriority(nil)",
                "lambda" => lambda { Waves::listingItemsPriority(nil) }
            },
            {
                "name" => "Waves::listingItemsLeisure(nil)",
                "lambda" => lambda { Waves::listingItemsLeisure(nil) }
            },
            {
                "name" => "NxTasks::listingItems(nil)",
                "lambda" => lambda { NxTasks::listingItems(nil) }
            },
            {
                "name" => "TheLine::getReference()",
                "lambda" => lambda { TheLine::getReference() }
            },
            {
                "name" => "TheLine::getCurrentCount()",
                "lambda" => lambda { TheLine::getCurrentCount() }
            },
            {
                "name" => "NxBoards::boardsOrdered()",
                "lambda" => lambda { NxBoards::boardsOrdered() }
            },
        ]

        runTest = lambda {|test|
            t1 = Time.new.to_f
            (1..3).each{ test["lambda"].call() }
            t2 = Time.new.to_f
            {
                "name" => test["name"],
                "runtime" => (t2 - t1).to_f/3
            }
        }

        printTestResults = lambda{|result, padding|
            puts "- #{result["name"].ljust(padding)} : #{"%6.3f" % result["runtime"]}"
        }

        padding = tests.map{|test| test["name"].size }.max

        # dry run to initialise things

        tests
            .each{|test|
                test["lambda"].call()
            }

        # tests

        results1 = tests
                    .map{|test|
                        puts "running: #{test["name"]}"
                        runTest.call(test)
                    }
                    .sort{|r1, r2| r1["runtime"] <=> r2["runtime"] }
                    .reverse

        results2 = [
            {
                "name" => "Listing::printListing()",
                "lambda" => lambda { Listing::printListing(ItemStore.new()) }
            },
            {
                "name" => "TheLine::line()",
                "lambda" => lambda { TheLine::line() }
            },
            {
                "name" => "Listing::items()",
                "lambda" => lambda { Listing::items() }
            },

        ]
                    .map{|test|
                        puts "running: #{test["name"]}"
                        runTest.call(test)
                    }
                    .sort{|r1, r2| r1["runtime"] <=> r2["runtime"] }
                    .reverse

        puts ""

        results1
            .each{|result|
                printTestResults.call(result, padding)
            }

        puts ""

        results2
            .each{|result|
                printTestResults.call(result, padding)
            }

        LucilleCore::pressEnterToContinue()
    end

    # Listing::items()
    def self.items()
        [
            Anniversaries::listingItems(),
            Desktop::listingItems(),
            NxListingPriorities::listingItems(nil),
            Waves::listingItemsPriority(nil),
            DevicesBackups::listingItems(),
            NxFires::listingItems(nil),
            NxLines::items(),
            NxFloats::listingItems(nil),
            NxOndates::listingItems(),
            TxNumberTargets::listingItems(),
            NxBoards::listingItems(),
            NxProjects::listingItems(nil),
            NxOpenCycles::items(nil),
            Waves::listingItemsLeisure(nil),
            NxTasks::listingItems(nil)
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item) or NxBalls::itemIsActive(item) }
            .reduce([]){|selected, item|
                if selected.map{|i| [i["uuid"], i["targetuuid"]].compact }.flatten.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
    end

    # Listing::itemToListingLine(store or nil, item)
    def self.itemToListingLine(store, item)
        storePrefix = store ? "(#{store.prefixString()})" : "     "
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{CoreData::itemToSuffixString(item)}#{BoardsAndItems::toStringSuffix(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{NxNotes::toStringSuffix(item)}"
        if Listing::shouldBeInYellow(item) then
            line = line.yellow
        end
        if NxBalls::itemIsRunning(item) or NxBalls::itemIsPaused(item) then
            line = line.green
        end
        line
    end

    # Listing::canBeDefault(item)
    def self.canBeDefault(item)
        return false if (item["parking"] and (Time.new.to_i - item["parking"]) < 3600*6)
        return false if item["mikuType"] == "NxBoard"
        return false if item["mikuType"] == "NxFloat"
        true
    end

    # Listing::shouldBeInYellow(item)
    def self.shouldBeInYellow(item)
        return true if (item["parking"] and (Time.new.to_i - item["parking"]) < 3600*6)
        return true if item["mikuType"] == "NxBoard"
        return true if item["mikuType"] == "NxFloat"
        false
    end

    # Listing::printListing(store)
    def self.printListing(store)
        system("clear")

        spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - NxBoards::boardsOrdered().size - NxProjects::items().size - 4 )

        spacecontrol.putsline ""

        Listing::items()
            .each{|item|
                store.register(item, Listing::canBeDefault(item))
                spacecontrol.putsline Listing::itemToListingLine(store, item)
            }

        puts TheLine::line()

        NxBoards::boardsOrdered().each{|item|
            NxBoards::informationDisplay(store, item["uuid"])
        }
        NxProjects::items().each{|item|
            store.register(item, Listing::canBeDefault(item))
            puts Listing::itemToListingLine(store, item)
        }
    end

    # Listing::program()
    def self.program()

        initialCodeTrace = CommonUtils::stargateTraceCode()

        Thread.new {
            loop {
                sleep 60
                NxBalls::all()
                    .select{|ball| ball["type"] == "running" }
                    .select{|ball| (Time.new.to_f - ball["startunixtime"]) > 3600 }
                    .take(1)
                    .each{
                        CommonUtils::onScreenNotification("catalyst", "NxBall running for more than one hour")
                    }
            }
        }

        loop {

            if CommonUtils::stargateTraceCode() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("8fba6ab0-ce92-46af-9e6b-ce86371d643d", 3600*12) then
                if Config::isPrimaryInstance() then 
                    system("#{File.dirname(__FILE__)}/../vienna-import")
                end
            end

            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/NxTasks-FrontElements-BufferIn")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTasks::bufferInImport(location)
                    puts "Picked up from NxTasks-FrontElements-BufferIn: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }

            if Config::isPrimaryInstance() then
                NxBoards::timeManagement()
                NxTimePromises::operate()
                NxOpenCycles::dataManagement()
                N3Objects::fileManagement()
                BankCore::fileManagement()
            end

            store = ItemStore.new()

            Listing::printListing(store)

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            next if input == ""

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end
end
