

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

class Speedometer
    def initialize()
    end

    def start_contest()
        @contest = []
    end

    def contest_entry(description, l)
        t1 = Time.new.to_f
        l.call()
        t2 = Time.new.to_f
        @contest << {
            "description" => description,
            "time"        => t2 - t1
        }
    end

    def end_contest()
        @contest
            .sort_by{|entry| entry["time"] }
            .reverse
            .each{|entry| puts "#{"%6.2f" % entry["time"]}: #{entry["description"]}" }
    end

    def start_unit(description)
        @description = description
        @t = Time.new.to_f
    end

    def end_unit()
        puts "#{"%6.2f" % (Time.new.to_f - @t)}: #{@description}"
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

        return false if TmpSkip1::isSkipped(item)

        if item["mikuType"] == "NxTime" then
            return NxTimes::isPending(item)
        end

        return false if item["mikuType"] == "TxCore"

        return false if item["mikuType"] == "DesktopTx1"

        return false if !DoNotShowUntil::isVisible(item)

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

    # Listing::chasingTheDragon()
    def self.chasingTheDragon()
        threads1 = Cubes::mikuType("NxThread")
            .select{|thread| thread["priority"]}
            .select{|thread| TxDrives::ratio(thread) < 1 }
            .sort_by{|thread| TxDrives::ratio(thread) }

        threads2 = Cubes::mikuType("TxCore")
            .select{|core| Catalyst::listingCompletionRatio(core) < 1 }
            .sort_by{|core| Catalyst::listingCompletionRatio(core) }
            .map{|core| 
                TxCores::elementsInOrder(core).reduce([]){|selected, thread|
                    if selected.size >= 6 then
                        selected
                    else
                        if Bank::recoveredAverageHoursPerDay(thread["uuid"]) < 1 then
                            selected + [thread]
                        else
                            selected
                        end
                    end
                }
            }
            .flatten
        threads1 + threads2
    end

    # Listing::items()
    def self.items()
        cores = TxCores::coresForListing()

        [
            NxBalls::runningItems(),
            Anniversaries::listingItems(),
            DropBox::items(),
            PhysicalTargets::listingItems(),
            Cubes::mikuType("NxLine"),
            NxTimeCounterDowns::listingItems(),
            Waves::listingItems().select{|item| item["interruption"] },
            NxOndates::listingItems(),
            NxBackups::listingItems(),
            Waves::listingItems().select{|item| !item["interruption"] },
            Cubes::mikuType("NxTask").select{|item| item["lineage-nx128"].nil? }.sort_by{|item| item["unixtime"] },
            Cubes::mikuType("NxThread").select{|item| item["lineage-nx128"].nil? }.sort_by{|item| item["unixtime"] },
            Listing::chasingTheDragon()
        ]
            .flatten
            .select{|item| Listing::listable(item) }
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
            .map{|item|
                TxDrives::checkPriorityLiveness(item)
            }
    end

    # Listing::toString2(store, item)
    def self.toString2(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        queueSuffix = lambda{|item|
            return "" if item["ordinal-1324"].nil?
            ordinal = item["ordinal-1324"]
            " [#{"%5.2f" % ordinal}]".green
        }

        line = "#{storePrefix}#{queueSuffix.call(item)} #{PolyFunctions::toString(item)}#{PolyFunctions::lineageSuffix(item).yellow}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil::suffixString(item)}#{TmpSkip1::skipSuffix(item)}"

        if !DoNotShowUntil::isVisible(item) and !NxBalls::itemIsActive(item) then
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

    # -----------------------------------------
    # Ops

    # Listing::speedTest()
    def self.speedTest()

        spot = Speedometer.new()

        spot.start_contest()
        spot.contest_entry("Anniversaries::listingItems()", lambda{ Anniversaries::listingItems() })
        spot.contest_entry("NxBalls::runningItems()", lambda{ NxBalls::runningItems() })
        spot.contest_entry("NxBackups::listingItems()", lambda{ NxBackups::listingItems() })
        spot.contest_entry("NxOndates::listingItems()", lambda{ NxOndates::listingItems() })
        spot.contest_entry("NxTimes::itemsWithPendingTime()", lambda{ NxTimes::itemsWithPendingTime() })
        spot.contest_entry("NxTimes::listingItems()", lambda{ NxTimes::listingItems() })
        spot.contest_entry("PhysicalTargets::listingItems()", lambda{ PhysicalTargets::listingItems() })
        spot.contest_entry("Waves::listingItems()", lambda{ Waves::listingItems() })
        spot.end_contest()

        puts ""

        spot.start_unit("Listing::maintenance()")
        Listing::maintenance()
        spot.end_unit()

        cores = Cubes::mikuType("TxCore")
        spot.start_unit("Listing::items()")
        items = Listing::items()
        spot.end_unit()

        spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
        store = ItemStore.new()

        LucilleCore::pressEnterToContinue()
    end

    # Listing::maintenance()
    def self.maintenance()
        if Config::isPrimaryInstance() then
            puts "> Listing::maintenance() on primary instance"
            Bank::fileManagement()
            NxTasks::maintenance()
            TxCores::maintenance2()
            CUtils3X::scan_merge()
            Catalyst::maintenance()
            NxThreads::maintenance()
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
                    .each{ CommonUtils::onScreenNotification("catalyst", "NxBall running for more than one hour") }
            }
        }
    end

    # Listing::checkForCodeUpdates()
    def self.checkForCodeUpdates()
        if CommonUtils::isOnline() and (CommonUtils::localLastCommitId() != CommonUtils::remoteLastCommitId()) then
            puts "Attempting to download new code"
            system("#{File.dirname(__FILE__)}/../pull-from-origin")
        end
    end

    # Listing::queueCommands()
    def self.queueCommands()
        "q: insert item <n> <ordinal> | q: new top line | q: insert line at <ordinal> | q: target: <time in hours> hours of <n> at <ordinal> | q: drop <n>"
    end

    # Listing::queueSorting(items)
    def self.queueSorting(items)
        i1s, i2s = items.partition{|item| item["ordinal-1324"] }
        i1s = i1s.sort_by{|item| item["ordinal-1324"] }

        if i1s.size > 0 then
            XCache::set("42546732-27a9-4c67-bac4-4970e3acb833", i1s[0]["ordinal-1324"])
        else
            XCache::set("42546732-27a9-4c67-bac4-4970e3acb833", 0)
        end

        x1 = i1s.size > 0 ? [{"uuid" => "aa9062ea-e56a-4d51-b15e-630da0c00326", "mikuType" => "TxEmpty"}] : []

        i1s + x1 + i2s
    end

    # Listing::main()
    def self.main()

        initialCodeTrace = CommonUtils::catalystTraceCode()

        latestCodeTrace = initialCodeTrace

        Thread.new {
            loop {
                Listing::checkForCodeUpdates()
                sleep 300
            }
        }

        loop {

            if CommonUtils::catalystTraceCode() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            if (Time.new.to_f - XCache::getOrDefaultValue("liveness:0340e024-58b3-4eb7", "0").to_i) > 3600 then
                # The deamon hits every 10 minutes, so an hour is ok.
                puts "I am not seeing activity from CUtils3X::scan_mikuTypes_updates"
                LucilleCore::pressEnterToContinue()
            end

            if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 3600) then
                Listing::maintenance()
            end

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
            store = ItemStore.new()

            system("clear")

            spacecontrol.putsline ""
            spacecontrol.putsline Listing::queueCommands()
            spacecontrol.putsline ""

            cores = TxCores::coresForListing()
            if cores.size > 0 then
                cores
                    .each{|item|
                        store.register(item, Listing::canBeDefault(item))
                        status = spacecontrol.putsline Listing::toString2(store, item)
                        break if !status
                    }
                spacecontrol.putsline ""
            end

            times = NxTimes::listingItems()
            if times.size > 0 then
                times
                    .each{|item|
                        store.register(item, Listing::canBeDefault(item))
                        status = spacecontrol.putsline Listing::toString2(store, item)
                        break if !status
                    }
                spacecontrol.putsline ""
            end

            desktopItems = Desktop::listingItems()
            if desktopItems.size > 0 then
                desktopItems
                    .each{|item|
                        store.register(item, false)
                        status = spacecontrol.putsline Listing::toString2(store, item)
                        break if !status
                    }
                spacecontrol.putsline ""
            end

            items = Listing::items()
            items = Listing::queueSorting(items)
            items = Prefix::prefix(items)
            items
                .each{|item|
                    if item["mikuType"] == "TxEmpty" then
                        spacecontrol.putsline ""
                        next
                    end
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::toString2(store, item)
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"

            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end
