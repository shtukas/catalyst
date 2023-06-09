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

    # Listing::tmpskip1(item, hours)
    def self.tmpskip1(item, hours)
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

    # Listing::skipSuffix(item)
    def self.skipSuffix(item)
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

        if skipTargetTimeOrNull.call(item) then
            " (tmpskip1'ed)".yellow
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

    # Listing::items1()
    def self.items1()

        burners = Solingen::mikuTypeItems("NxBurner")

        fires = Solingen::mikuTypeItems("NxFire")

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

        anniversaries = Anniversaries::listingItems()

        waves = Waves::listingItems()

        interruptions =
            [
                waves.select{|item| item["interruption"] },
                PhysicalTargets::listingItems()
            ]
            .flatten

        backups = NxBackups::listingItems()

        ondates = NxOndates::listingItems()

        drops = Solingen::mikuTypeItems("NxDrop")
                    .sort_by{|item| item["unixtime"] }

        cliques = Solingen::mikuTypeItems("TxClique")
                    .select{|clique| TxCliques::listingRatio(clique) < 1 }
                    .sort_by{|clique| TxCliques::listingRatio(clique) }

        tasks = 
            if cliques.empty? then
                []
            else
                TxCliques::cliqueToNxTasks(cliques.first).sort_by{|item| item["position"] }.first(5)
            end

        items = [
            anniversaries,
            interruptions,
            backups,
            ondates,
            waves.select{|item| !item["interruption"] },
            drops,
            tasks,
            cliques,
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

    # Listing::itemToListingLine(store: nil, item: nil)
    def self.itemToListingLine(store: nil, item: nil)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        str1 = PolyFunctions::toString(item)

        line = "#{storePrefix} #{str1}#{CoreData::itemToSuffixString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{NxNotes::toStringSuffix(item)}#{DoNotShowUntil::suffixString(item)}#{Listing::skipSuffix(item)}"

        if Listing::isInterruption(item) then
            line = line.gsub("Px02", "🧀 ")
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
                "name" => "Listing::items1()",
                "lambda" => lambda { Listing::items1() }
            },
            {
                "name" => "Listing::items2()",
                "lambda" => lambda { Listing::items2() }
            },
            {
                "name" => "Listing::printEvalItems()",
                "lambda" => lambda { Listing::printEvalItems(ItemStore.new(), Listing::items()) }
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
             NxTimeCapsules::operate()
             NxTimePromises::operate()
             Bank::fileManagement()
             NxBackups::dataMaintenance()
        end
        TxCliques::management()
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

    # Listing::printEvalItems(store, items1, items2)
    def self.printEvalItems(store, items1, items2)
        system("clear")

        spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

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

        if items1.size > 0 then
            spacecontrol.putsline ""
            items1
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::itemToListingLine(store: store, item: item)
                    break if !status
                }
        end

        if items2.size > 0 then
            spacecontrol.putsline ""
            items2
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

            Listing::printEvalItems(store, Listing::items1(), Listing::items2())

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            next if input == ""

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end
