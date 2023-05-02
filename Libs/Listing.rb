# encoding: UTF-8

class SpaceControl

    def initialize(remaining_vertical_space)
        @remaining_vertical_space = remaining_vertical_space
    end

    def putsline(line) # boolean
        vspace = CommonUtils::verticalSize(line)
        return false if vspace > @remaining_vertical_space
        puts line
        @remaining_vertical_space = @remaining_vertical_space - vspace
        true
    end
end

class Listing

    # Listing::listingCommands()
    def self.listingCommands()
        [
            "on items : .. | <datecode> | access (<n>) | do not show until <n> | done (<n>) | program (<n>) | expose (<n>) | add time <n> | board (<n>) | unboard <n> | note (<n>) | ordinal <n> <ordinal> | rotate <n> | coredata <n> | destroy <n>",
            "makers   : anniversary | manual countdown | wave | today | tomorrow | ondate | desktop | task | fire | project | drop | float | ordinal line <ordinal> <line>",
            "",
            "specific types commands:",
            "    - boards  : engine (<n>)",
            "    - tasks   : engine (<n>) | position <n> | coordinates <n>",
            "    - ondate  : redate",
            "",
            "transmutation : recast (<n>)",
            "divings       : anniversaries | ondates | waves | todos | desktop | time promises | boards | tasks",
            "NxBalls       : start | start * | stop | stop * | pause | pursue",
            "misc          : search | speed | commands | mikuTypes | edit <n>",
        ].join("\n")
    end

    # Listing::tmpskip1(item, hours = 1)
    def self.tmpskip1(item, hours = 1)
        directive = {
            "unixtime"        => Time.new.to_f,
            "durationInHours" => hours
        }
        item["tmpskip1"] = directive
        puts JSON.pretty_generate(item)
        N3Objects::commit(item)
        # The backup items are dynamically generated and do not correspond to item
        # in the database. We also put the skip directive to the cache
        XCache::set("464e0d79-36b5-4bb6-951c-4d91d661ac6f:#{item["uuid"]}", JSON.generate(directive))
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
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::doubleDot(item)
            return
        end

        if Interpreting::match(">>", input) then
            item = store.getDefault()
            return if item.nil?
            Listing::tmpskip1(item)
            return
        end

        if Interpreting::match(">> *", input) then
            _, durationInHours = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            item["tmpskip1"] = {
                "unixtime"        => Time.new.to_f,
                "durationInHours" => durationInHours.to_f
            }
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
            return
        end

        if Interpreting::match("add time *", input) then
            _, _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
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
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::access(item)
            return
        end

        if Interpreting::match("anniversary", input) then
            Anniversaries::issueNewAnniversaryOrNullInteractively()
            return
        end

        if Interpreting::match("anniversaries", input) then
            Anniversaries::program2()
            return
        end

        if Interpreting::match("board", input) then
            item = store.getDefault()
            return if item.nil?
            puts "boarding: #{PolyFunctions::toString(item).green}"
            BoardsAndItems::askAndMaybeAttach(item)
            return
        end

        if Interpreting::match("board *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            BoardsAndItems::askAndMaybeAttach(item)
            return
        end

        if input.start_with?("ordinal line") then
            input = input[12, 999].strip
            targetordinal = input.to_f
            line = input[targetordinal.to_f, 999].strip
            item = NxLines::issue(line)
            BoardsAndItems::maybeAskAndMaybeAttach(item)
            fronti = NxFrontOrdinals::issue(item["uuid"], targetordinal)
            puts JSON.pretty_generate(fronti)
            return
        end

        if Interpreting::match("ordinal * *", input) then
            _, itemordinal, frontordinal = Interpreting::tokenizer(input)
            item = store.get(itemordinal.to_i)
            return if item.nil?
            NxFrontOrdinals::destroyByTargetUUID(item["uuid"])
            item = NxFrontOrdinals::issue(item["uuid"], frontordinal.to_f)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("boards", input) then
            NxBoards::program3()
            return
        end

        if Interpreting::match("tasks", input) then
            NxTasks::program1()
            return
        end

        if Interpreting::match("unboard *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            item["boarduuid"] = nil
            N3Objects::commit(item)
            return
        end

        if Interpreting::match("time promises", input) then
            NxTimePromises::show()
            return
        end

        if Interpreting::match("coredata *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            reference =  CoreData::interactivelyMakeNewReferenceStringOrNull(item["uuid"])
            return if reference.nil?
            item["field11"] = reference
            N3Objects::commit(item)
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
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
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
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::done(item)
            return
        end

        if Interpreting::match("rotate *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxBalls::stop(item)
            NxFrontOrdinals::rotateCatalystItem(item)
            return
        end

        if Interpreting::match("destroy *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::destroy(item)
            return
        end

        if Interpreting::match("position *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] != "NxTask" then
                puts "position is only available to NxTasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            item["position"] = NxTasksPositions::decidePositionAtOptionalBoarduuid(item["boarduuid"])
            puts JSON.pretty_generate(item)
            N3Objects::commit(item)
            return
        end

        if Interpreting::match("coordinates *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if item["mikuType"] != "NxTask" then
                puts "coordinates is only available to NxTasks"
                LucilleCore::pressEnterToContinue()
                return
            end
            item = NxTasks::recoordinates(item)
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("do not show until *", input) then
            _, _, _, _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
            return if unixtime.nil?
            DoNotShowUntil::setUnixtime(item, unixtime)
            return
        end

        if Interpreting::match("engine", input) then
            item = store.getDefault()
            return if item.nil?
            if !["NxBoard", "NxTask"].include?(item["mikuType"]) then
                puts "Only NxBoard and NxTask are carrying engine"
                LucilleCore::pressEnterToContinue()
                return
            end
            engine = TxEngines::interactivelyMakeEngineOrDefault()
            return if engine.nil?
            item["engine"] = engine
            N3Objects::commit(item)
            return
        end

        if Interpreting::match("engine *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            if !["NxBoard", "NxTask"].include?(item["mikuType"]) then
                puts "Only NxBoard and NxTask are carrying engine"
                LucilleCore::pressEnterToContinue()
                return
            end
            engine = TxEngines::interactivelyMakeEngineOrDefault()
            return if engine.nil?
            item["engine"] = engine
            N3Objects::commit(item)
            return
        end

        if Interpreting::match("expose", input) then
            item = store.getDefault()
            return if item.nil?
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("expose *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("edit *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
            N3Objects::commit(item)
            return
        end

        if Interpreting::match("task", input) then
            item = NxTasks::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            return
        end

        if Interpreting::match("program", input) then
            item = store.getDefault()
            return if item.nil?
            PolyActions::program(item)
            return
        end

        if Interpreting::match("program *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::program(item)
            return
        end

        if Interpreting::match("mikuTypes", input) then
            puts N3Objects::getall().map{|item| item["mikuType"] }.uniq
            LucilleCore::pressEnterToContinue()
            return
        end

        if Interpreting::match("manual countdown", input) then
            PhysicalTargets::issueNewOrNull()
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
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            NxNotes::edit(item)
            return
        end

        if Interpreting::match("ondate", input) then
            item = NxOndates::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::maybeAskAndMaybeAttach(item)
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
            BoardsAndItems::maybeAskAndMaybeAttach(item)
            return
        end

        if Interpreting::match("float", input) then
            item = NxFloats::interactivelyIssueNewOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::maybeAskAndMaybeAttach(item)
            return
        end

        if Interpreting::match("pause", input) then
            item = store.getDefault()
            return if item.nil?
            NxBalls::pause(item)
            return
        end

        if Interpreting::match("pause *", input) then
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
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
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
            return if item.nil?
            PolyActions::pursue(item)
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
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
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
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
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
            _, listord = Interpreting::tokenizer(input)
            item = store.get(listord.to_i)
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
            BoardsAndItems::maybeAskAndMaybeAttach(item)
            return
        end

        if Interpreting::match("tomorrow", input) then
            item = NxOndates::interactivelyIssueNewTodayOrNull()
            return if item.nil?
            item["datetime"] = "#{CommonUtils::nDaysInTheFuture(1)} 07:00:00+00:00"
            N3Objects::commit(item)
            puts JSON.pretty_generate(item)
            BoardsAndItems::maybeAskAndMaybeAttach(item)
            return
        end

        if input == "wave" then
            item = Waves::issueNewWaveInteractivelyOrNull()
            return if item.nil?
            puts JSON.pretty_generate(item)
            BoardsAndItems::maybeAskAndMaybeAttach(item)
            return
        end

        if input == "waves" then
            Waves::program()
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
                "name" => "PhysicalTargets::listingItems()",
                "lambda" => lambda { PhysicalTargets::listingItems() }
            },
            {
                "name" => "Waves::listingItems()",
                "lambda" => lambda { Waves::listingItems() }
            },
            {
                "name" => "TheLine::line()",
                "lambda" => lambda { TheLine::line() }
            },
            {
                "name" => "NxFloats::items()",
                "lambda" => lambda { NxFloats::items() }
            },
            {
                "name" => "NxFires::items()",
                "lambda" => lambda { NxFires::items() }
            },
            {
                "name" => "NxTasks::listingItems()",
                "lambda" => lambda { NxTasks::listingItems() }
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
                "name" => "Listing::items()",
                "lambda" => lambda { Listing::items() }
            },
            {
                "name" => "Listing::printItems()",
                "lambda" => lambda { Listing::printItems(ItemStore.new(), Listing::items()) }
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

    # Listing::listable(item)
    def self.listable(item)
        return true if NxBalls::itemIsActive(item)
        return false if !DoNotShowUntil::isVisible(item)
        if item["boarduuid"] then
            board = N3Objects::getOrNull(item["boarduuid"])
            return false if !DoNotShowUntil::isVisible(board)
        end
        true
    end

    # Listing::priorityQueue(queue1)
    def self.priorityQueue(queue1)
        queue1uuids = queue1.map{|i| i["uuid"] }
        [
            PhysicalTargets::listingItems(),
            Anniversaries::listingItems(),
            Desktop::listingItems(),
            Waves::listingItems(),
            NxOndates::listingItems(),
            NxFires::items(),
            NxBackups::listingItems(),
            NxLines::items(),
            NxBoards::listingItems(),
            NxTasks::listingItems(),
        ]
            .flatten
            .select{|item| !queue1uuids.include?(item["uuid"]) }
            .select{|item| Listing::listable(item) }
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"]}.flatten.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
    end

    # Listing::items()
    def self.items()
        queue1 = NxFrontOrdinals::queue1()
        queue2 = Listing::priorityQueue(queue1)
        NxFrontOrdinals::dataManagement(queue2)
        queue1 + queue2
    end

    # Listing::skipfragment(item)
    def self.skipfragment(item)
        skipDirectiveOrNull = lambda {|item|
            if item["tmpskip1"] then
                return item["tmpskip1"]
            end
            cachedDirective = XCache::getOrNull("464e0d79-36b5-4bb6-951c-4d91d661ac6f:#{item["uuid"]}")
            if cachedDirective then
                return JSON.parse(cachedDirective)
            end
        }

        skipTargetTimeOrNull = lambda {|item|
            directive = skipDirectiveOrNull.call(item)
            return nil if directive.nil?
            targetTime = directive["unixtime"] + directive["durationInHours"]*3600
            (Time.new.to_f < targetTime) ? targetTime : nil
        }

        targetTime = skipTargetTimeOrNull.call(item)
        if targetTime then
            "(tmpskip1'ed for #{((targetTime-Time.new.to_f).to_f/3600).round(2)} more hours) ".yellow
        else
            ""
        end
    end

    # Listing::itemToListingLine(store: nil, item: nil)
    def self.itemToListingLine(store: nil, item: nil)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "
        line = "#{storePrefix} Px02Px03#{Listing::skipfragment(item)}#{PolyFunctions::toString(item)}#{CoreData::itemToSuffixString(item)}#{BoardsAndItems::toStringSuffix(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{NxNotes::toStringSuffix(item)}#{DoNotShowUntil::suffixString(item)}"
        if item["interruption"] then
            line = line.gsub("Px02", "(interruption) ".red)
        else
            line = line.gsub("Px02", "")
        end
        if item[:isFifo] then
            line = line.gsub("Px03", "(ordinal: #{"%5.2f" % item[:fifoOrdinal]}) ".green)
        else
            line = line.gsub("Px03", "")
        end
        if NxBalls::itemIsActive(item) then
            line = line.green
        end
        if !DoNotShowUntil::isVisible(item) and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end
        if item[:taskTimeOverflow] and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end
        line
    end

    # Listing::canBeDefault(item)
    def self.canBeDefault(item)
        return true if NxBalls::itemIsRunning(item)

        return false if item["mikuType"] == "NxBoard"
        return false if item["mikuType"] == "DesktopTx1"
        return false if item["mikuType"] == "NxFloat"
        return false if !DoNotShowUntil::isVisible(item)
        return false if (item[:taskTimeOverflow] and !NxBalls::itemIsActive(item))

        skipDirectiveOrNull = lambda {|item|
            if item["tmpskip1"] then
                return item["tmpskip1"]
            end
            cachedDirective = XCache::getOrNull("464e0d79-36b5-4bb6-951c-4d91d661ac6f:#{item["uuid"]}")
            if cachedDirective then
                return JSON.parse(cachedDirective)
            end
        }

        skipTargetTimeOrNull = lambda {|item|
            directive = skipDirectiveOrNull.call(item)
            return nil if directive.nil?
            targetTime = directive["unixtime"] + directive["durationInHours"]*3600
            (Time.new.to_f < targetTime) ? targetTime : nil
        }

        return false if skipTargetTimeOrNull.call(item)

        true
    end

    # Listing::isInterruption(item)
    def self.isInterruption(item)
        item["interruption"] # this is only carried by some waves at the moment
    end

    # Listing::dataMaintenance()
    def self.dataMaintenance()
        if Config::isPrimaryInstance() then
            LucilleCore::locationsAtFolder("#{ENV['HOME']}/Galaxy/DataHub/NxTasks-FrontElements-BufferIn")
                .each{|location|
                    next if File.basename(location).start_with?(".")
                    item = NxTasks::bufferInImport(location)
                    puts "Picked up from NxTasks-FrontElements-BufferIn: #{JSON.pretty_generate(item)}"
                    LucilleCore::removeFileSystemLocation(location)
                }
        end

        if Config::isPrimaryInstance() and ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("c8793d37-0a9c-48ec-98f7-d0e1f8f5744c", 86400) then
            generalpermission = false
            count = 0
            N3Objects::getall().each{|item|
                next if item["boarduuid"].nil?
                next if NxBoards::getItemOfNull(item["boarduuid"])
                break if count > 100
                puts "item: #{JSON.pretty_generate(item)}"
                puts "could not find the board".green
                if !generalpermission then
                    puts "repairing ? ".green
                    LucilleCore::pressEnterToContinue()
                    generalpermission = true
                end
                item["boarduuid"] = nil
                N3Objects::commit(item)
                count = count + 1
            }

        end

        if Config::isPrimaryInstance() then
            NxTimePromises::operate()
            N3Objects::fileManagement()
            Bank::fileManagement()
            NxBackups::dataManagement()
        end
    end

    # Listing::launchNxBallMonitor()
    def self.launchNxBallMonitor()
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
    end

    # Listing::getNxFrontOrdinalForUuidOrNull(uuid)
    def self.getNxFrontOrdinalForUuidOrNull(uuid)
        NxFrontOrdinals::items().select{|item| item["targetuuid"] == uuid }.first
    end

    # Listing::printItems(store, items)
    def self.printItems(store, items)
        system("clear")

        spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

        spacecontrol.putsline ""
        puts TheLine::line()

        floats = NxFloats::items().select{|item| item["boarduuid"].nil? }
        if !floats.empty? then
            spacecontrol.putsline ""
            floats
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    spacecontrol.putsline Listing::itemToListingLine(store: store, item: item)
                }
        end

        boards = CommonUtils::putFirst(NxBoards::boardsOrdered().select{|board| NxBoards::completionRatio(board) < 1 and Listing::listable(board) }, lambda{|board| DoNotShowUntil::isVisible(board) })
        if !boards.empty? then
            boards.each{|board|
                store.register(board, Listing::canBeDefault(board))
                spacecontrol.putsline Listing::itemToListingLine(store: store, item: board)
            }
        end

        spacecontrol.putsline ""

        active, items = items.partition{|item| NxBalls::itemIsActive(item) }
        active
            .each{|item|
                store.register(item, Listing::canBeDefault(item))
                spacecontrol.putsline Listing::itemToListingLine(store: store, item: item)
            }

        interruption, items = items.partition{|item| Listing::isInterruption(item) }
        interruption
            .each{|item|
                store.register(item, Listing::canBeDefault(item))
                spacecontrol.putsline Listing::itemToListingLine(store: store, item: item)
            }

        items
            .each{|item|
                store.register(item, Listing::canBeDefault(item))
                status = spacecontrol.putsline Listing::itemToListingLine(store: store, item: item)
                break if !status
            }
    end

    # Listing::main()
    def self.main()
        initialCodeTrace = CommonUtils::stargateTraceCode()

        Thread.new {
            loop {
                if CommonUtils::isOnline() and (CommonUtils::localLastCommitId() != CommonUtils::remoteLastCommitId()) then
                    puts "Attempting to download new code"
                    system("#{File.dirname(__FILE__)}/../pull-from-origin")
                end
                sleep 300
            }
        }

        loop {

            if CommonUtils::stargateTraceCode() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            Listing::dataMaintenance()

            store = ItemStore.new()

            Listing::printItems(store, Listing::items())

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            next if input == ""

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end
end
