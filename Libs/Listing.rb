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

    # -----------------------------------------
    # Data

    # Listing::tmpskip1(item, hours = 1)
    def self.tmpskip1(item, hours = 1)
        directive = {
            "unixtime"        => Time.new.to_f,
            "durationInHours" => hours
        }
        puts JSON.pretty_generate(directive)
        Solingen::setAttribute2(item["uuid"], "tmpskip1", directive)
        # The backup items are dynamically generated and do not correspond to item
        # in the database. We also put the skip directive to the cache
        XCache::set("464e0d79-36b5-4bb6-951c-4d91d661ac6f:#{item["uuid"]}", JSON.generate(directive))
    end

    # Listing::listable(item)
    def self.listable(item)
        return true if NxBalls::itemIsActive(item)
        return false if !DoNotShowUntil::isVisible(item)
        true
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

    # Listing::canBeDefault(item)
    def self.canBeDefault(item)
        return true if NxBalls::itemIsRunning(item)

        return false if item["mikuType"] == "DesktopTx1"
        return false if item["mikuType"] == "NxFire"
        return false if item["mikuType"] == "NxBurner"
        return false if item["mikuType"] == "NxTime"
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
        item["interruption"]
    end

    # Listing::items()
    def self.items()

        anniversary = Anniversaries::listingItems()

        burners = Solingen::mikuTypeItems("NxBurner")
                    .select{|burner| burner["engineuuid"].nil? }

        fires = Solingen::mikuTypeItems("NxFire")

        waves = Waves::listingItems()

        interruptions =
            [
                waves.select{|item| item["interruption"] },
                PhysicalTargets::listingItems()
            ]
            .flatten

        backups = NxBackups::listingItems()

        ondates = NxOndates::listingItems()

        tasks = Solingen::mikuTypeItems("NxTask")
                    .sort_by{|item| item["clique"]["position"] }

        enginestasks = Solingen::mikuTypeItems("TxEngine")
            .select{|engine| DoNotShowUntil::isVisible(engine) or NxBalls::itemIsActive(engine) }
            .sort_by{|engine| TxEngines::listingCompletionRatio(engine) }
            .select{|engine| TxEngines::listingCompletionRatio(engine) < 1 or NxBalls::itemIsActive(engine) }
            .map{|engine| TxEngines::engineToListingTasks(engine) }
            .flatten

        runningEngines, runningItemsNonEngine = NxBalls::runningItems().partition{|item| item["mikuType"] == "TxEngine" }

        items = [
            runningItemsNonEngine,
            anniversary,
            Desktop::listingItems(),
            burners,
            fires,
            interruptions,
            backups,
            ondates,
            waves.select{|item| !item["interruption"] },
            enginestasks,
            tasks.first(10)
        ]
            .flatten
            .select{|item| Listing::listable(item) }
            .reduce([]){|selected, item|
                if !selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected + [item]
                else
                    selected
                end
            }

        if runningEngines.size > 0 then
            uuids = runningEngines.map{|engine| engine["uuid"] }
            items = items.select{|item| uuids.include?(item["engineuuid"]) }
        end

        items
    end

    # Listing::itemToListingLine(store: nil, item: nil)
    def self.itemToListingLine(store: nil, item: nil)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        str1 = PolyFunctions::toString(item)
        if item["mikuType"] == "TxEngine" then
            str1 = TxEngines::toString(item, true)
        end

        itemToEngineSuffix = 
            if item["mikuType"] == "NxTask" then
                ""
            else
                TxEngines::itemToEngineSuffix(item)
            end

        line = "#{storePrefix} Px02#{Listing::skipfragment(item)}#{str1}#{CoreData::itemToSuffixString(item)}#{itemToEngineSuffix}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{NxNotes::toStringSuffix(item)}#{DoNotShowUntil::suffixString(item)}"

        if Listing::isInterruption(item) then
            line = line.gsub("Px02", "(intt) ".red)
        else
            line = line.gsub("Px02", "")
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        if !DoNotShowUntil::isVisible(item) and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end
        line
    end

    # -----------------------------------------
    # Ops

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
                "name" => "Solingen::mikuTypeItems(NxBurner)",
                "lambda" => lambda { Solingen::mikuTypeItems("NxBurner") }
            },
            {
                "name" => "Solingen::mikuTypeItems(NxFire)",
                "lambda" => lambda { Solingen::mikuTypeItems("NxFire") }
            },
            {
                "name" => "NxTimes::listingItems()",
                "lambda" => lambda { NxTimes::listingItems() }
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
                "name" => "Listing::printEvalItems()",
                "lambda" => lambda { Listing::printEvalItems(ItemStore.new(), TxEngines::listingItems(), Listing::items()) }
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

        padding = ([0] + Solingen::mikuTypeItems("TxEngine").map{|engine| engine["description"].size }).max
        XCache::set("engine-description-padding-26f3d54692dc", padding)

        if Config::isPrimaryInstance() then
             NxTimeCapsules::operate()
             NxTimePromises::operate()
             Bank::fileManagement()
             NxBackups::dataMaintenance()
             TxEngines::maintenance()
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

    # Listing::printEvalItems(store, prelude, items)
    def self.printEvalItems(store, prelude, items)
        system("clear")

        spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

        spacecontrol.putsline ""
        prelude
            .each{|item| 
                store.register(item, false)
                status = spacecontrol.putsline Listing::itemToListingLine(store: store, item: item)
                break if !status
            }

        times = NxTimes::listingItems()
        if times.size > 0 then
            spacecontrol.putsline ""
            times
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::itemToListingLine(store: store, item: item)
                    break if !status
                }
        end

        if items.size > 0 then
            spacecontrol.putsline ""
            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::itemToListingLine(store: store, item: item)
                    break if !status
                }
        end
    end

    # Listing::checkForCodeUpdates()
    def self.checkForCodeUpdates()
        if CommonUtils::isOnline() and (CommonUtils::localLastCommitId() != CommonUtils::remoteLastCommitId()) then
            puts "Attempting to download new code"
            system("#{File.dirname(__FILE__)}/../pull-from-origin")
        end
    end

    # Listing::main()
    def self.main()

        initialCodeTrace = CommonUtils::stargateTraceCode()

        Thread.new {
            loop {
                Listing::checkForCodeUpdates()
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

            Listing::printEvalItems(store, TxEngines::listingItems(), Listing::items())

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            next if input == ""

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end
