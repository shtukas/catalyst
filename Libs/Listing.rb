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

    # Listing::listable(item)
    def self.listable(item)
        return true if NxBalls::itemIsActive(item)
        return false if !DoNotShowUntil::isVisible(item)
        true
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

    # Listing::burnersAndFires()
    def self.burnersAndFires()

        burners = DarkEnergy::mikuType("NxBurner")

        fires = DarkEnergy::mikuType("NxFire")

        items = [
            Desktop::listingItems(),
            (burners + fires).sort_by{|item| item["unixtime"] }
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

        items
    end

    # Listing::items2()
    def self.items2()

        [
            Anniversaries::listingItems(),
            PhysicalTargets::listingItems(),
            Waves::listingItems().select{|item| item["interruption"] },
            NxBackups::listingItems(),
            NxOndates::listingItems(),
            DarkEnergy::mikuType("NxDrop"),
            NxCores::coreOwnedRunningTasks(),
            NxCores::listingItems(),
            Waves::listingItems().select{|item| !item["interruption"] },
            TxEngines::listingItems()
        ]
            .flatten
            .select{|item| Listing::listable(item) }
    end

    # Listing::itemToListingLine(store, item)
    def self.itemToListingLine(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        str1 = PolyFunctions::toString(item)

        interruptionPreffix = 
            if Listing::isInterruption(item) then
                "🧀 "
            else
                ""
            end

        line = "#{storePrefix} #{interruptionPreffix}#{str1}#{CoreData::itemToSuffixString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{NxNotes::toStringSuffix(item)}#{DoNotShowUntil::suffixString(item)}#{NxCores::coreSuffix(item).green}#{TxEngines::engineSuffix(item)}#{TmpSkip1::skipSuffix(item)}"

        if !DoNotShowUntil::isVisible(item) and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        if item["mikuType"] == "NxTask" and item["variant"] == "stack" then
             line = line + "\n" +  item["stack"]
                                        .sort_by{|entry| entry["position"] }
                                        .map{|entry| "               #{NxTasks::stackEntryToString(entry)}" }
                                        .join("\n")
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
                "name" => "NxBackups::listingItems()",
                "lambda" => lambda { NxBackups::listingItems() }
            },
            {
                "name" => "DarkEnergy::mikuType(NxDrop)",
                "lambda" => lambda { DarkEnergy::mikuType("NxDrop") }
            },
            {
                "name" => "NxCores::listingItems()",
                "lambda" => lambda { NxCores::listingItems() }
            },
            {
                "name" => "TheLine::line()",
                "lambda" => lambda { TheLine::line() }
            },
            {
                "name" => "DarkEnergy::mikuType(NxBurner)",
                "lambda" => lambda { DarkEnergy::mikuType("NxBurner") }
            },
            {
                "name" => "DarkEnergy::mikuType(NxFire)",
                "lambda" => lambda { DarkEnergy::mikuType("NxFire") }
            },
            {
                "name" => "NxTimes::listingItems()",
                "lambda" => lambda { NxTimes::listingItems() }
            },
            {
                "name" => "TxEngines::listingItems()",
                "lambda" => lambda { TxEngines::listingItems() }
            },
            {
                "name" => "NxCores::coreOwnedRunningTasksCore()",
                "lambda" => lambda { NxCores::coreOwnedRunningTasksCore() }
            },
            {
                "name" => "Listing::burnersAndFires()",
                "lambda" => lambda { Listing::burnersAndFires() }
            },
            {
                "name" => "Listing::maintenance()",
                "lambda" => lambda { Listing::maintenance() }
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
                "name" => "Listing::items2()",
                "lambda" => lambda { Listing::items2() }
            },
            {
                "name" => "Listing::printing sequenne",
                "lambda" => lambda { 
                    Listing::maintenance()

                    spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
                    store = ItemStore.new()

                    system("clear")

                    Listing::printing(
                        spacecontrol,
                        store, 
                        NxTimes::listingItems(),
                        DarkEnergy::mikuType("NxCore").sort_by{|core| NxCores::listingCompletionRatio(core) },
                        TxEngines::listingItems(),
                        Listing::burnersAndFires(),
                        Listing::items2()
                    )
                }
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

    # Listing::maintenance()
    def self.maintenance()
        NxCores::maintenance_all_instances()
        if Config::isPrimaryInstance() then
             NxTimePromises::operate()
             Bank::fileManagement()
             NxBackups::maintenance()
             NxBurners::maintenance()
             PositiveSpace::maintenance()
             NxCores::maintenance_leader_instance()
             NxTasks::maintenance()
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

    # Listing::printing(spacecontrol, store, times, coresd, enginesd, burnersAndFires, items2)
    def self.printing(spacecontrol, store, times, coresd, enginesd, burnersAndFires, items2)

        if times.size > 0 then
            spacecontrol.putsline ""
            times
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::itemToListingLine(store, item)
                    break if !status
                }
        end

        if coresd.size > 0 then
            spacecontrol.putsline ""
            coresd
                .each{|item|
                    store.register(item, false)
                    status = spacecontrol.putsline Listing::itemToListingLine(store, item)
                    break if !status
                }
        end

        if enginesd.size > 0 then
            spacecontrol.putsline ""
            enginesd
                .first(5)
                .each{|item|
                    store.register(item, false)
                    status = spacecontrol.putsline Listing::itemToListingLine(store, item)
                    break if !status
                }
        end

        if burnersAndFires.size > 0 then
            spacecontrol.putsline ""
            burnersAndFires
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::itemToListingLine(store, item)
                    break if !status
                }
        end

        if items2.size > 0 then
            spacecontrol.putsline ""
            items2
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::itemToListingLine(store, item)
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

            Listing::maintenance()

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
            store = ItemStore.new()

            system("clear")

            Listing::printing(
                spacecontrol,
                store, 
                NxTimes::listingItems(),
                DarkEnergy::mikuType("NxCore").sort_by{|core| NxCores::listingCompletionRatio(core) },
                TxEngines::listingItems(),
                Listing::burnersAndFires(),
                Listing::items2()
            )

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            next if input == ""

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end
