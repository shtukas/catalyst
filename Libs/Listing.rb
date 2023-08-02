

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

        return false if item["mikuType"] == "NxPrimeDirective"

        return false if item["mikuType"] == "DesktopTx1"

        return false if item["mikuType"] == "NxDelegate"

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

        return false if Bank::recoveredAverageHoursPerDay(item["uuid"]) >= 1

        true
    end

    # Listing::isInterruption(item)
    def self.isInterruption(item)
        item["interruption"]
    end

    # Listing::taskOrThreadsChildren(parent)
    def self.taskOrThreadsChildren(parent)
        items = Tx8s::childrenInOrder(parent)
                    .select{|item| item["mikuType"] == "NxTask" or item["mikuType"] == "NxThread" }
    end

    # Listing::tasksAndThreadsListingItemsInOrder(parents)
    def self.tasksAndThreadsListingItemsInOrder(parents)
        parents
            .map{|parent| Listing::taskOrThreadsChildren(parent) }
            .flatten
            .sort_by{|item| item["parent"]["position"] }
    end

    # Listing::items(parents)
    def self.items(parents)
        [
            NxBalls::runningItems(),
            Anniversaries::listingItems(),
            DropBox::items(),
            PhysicalTargets::listingItems(),
            NxBackups::listingItems(),
            Waves::listingItems().select{|item| item["interruption"] },
            NxOndates::listingItems(),
            NxDelegates::listingItems(parents),
            Waves::listingItems().select{|item| !item["interruption"] },
            NxTasks::orphanItems().sort_by{|item| item["unixtime"] },
            NxThreads::orphanItems().sort_by{|item| item["unixtime"] },
            Listing::tasksAndThreadsListingItemsInOrder(parents)
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
    end

    # Listing::toString2(store, item)
    def self.toString2(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{Tx8s::suffix(item).green}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil::suffixString(item)}#{TmpSkip1::skipSuffix(item)}"

        if !DoNotShowUntil::isVisible(item) and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if Bank::recoveredAverageHoursPerDay(item["uuid"]) >= 1 then
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
        spot.contest_entry("NxTasks::orphanItems()", lambda{ NxTasks::orphanItems() })
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

        cores = BladesGI::mikuType("TxCore")
        spot.start_unit("Listing::items(cores)")
        items = Listing::items(cores)
        spot.end_unit()

        spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
        store = ItemStore.new()

        LucilleCore::pressEnterToContinue()
    end

    # Listing::maintenance()
    def self.maintenance()
        if Config::isPrimaryInstance() then
            Bank::fileManagement()
            NxBackups::maintenance()
            NxTasks::maintenance()
            NxThreads::maintenance2()
            TxCores::maintenance2()
            NxDelegates::maintenance()
            BladesGx::scan_merge()
            Catalyst::maintenance()
        end
        NxThreads::maintenance1()
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

        Thread.new {
            loop {
                sleep 60
                BladesGx::loadInMemoryData()
                sleep 240
            }
        }

        loop {

            if CommonUtils::catalystTraceCode() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 3600) then
                Listing::maintenance()
            end

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
            store = ItemStore.new()

            system("clear")

            spacecontrol.putsline ""

            stack = Stack::items()
            if stack.size > 0 then
                spacecontrol.putsline "stack:".green
                stack
                    .each{|item|
                        spacecontrol.putsline PolyFunctions::toString(item)
                    }
                spacecontrol.putsline ""
            end

            directives = BladesGI::mikuType("NxPrimeDirective").sort_by{|item| item["unixtime"] }
            if directives.size > 0 then
                directives
                    .each{|item|
                        store.register(item, Listing::canBeDefault(item))
                        status = spacecontrol.putsline Listing::toString2(store, item).yellow
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

            cores = BladesGI::mikuType("TxCore")
                        .select{|core| TxCores::compositeCompletionRatio(core) < 1 }
                        .sort_by{|core| TxCores::compositeCompletionRatio(core) }

            items = Listing::items(cores)
            items = CommonUtils::putFirst(items, lambda{|item| NxBalls::itemIsRunning(item) })
            head = []
            tail = items
            loop {
                break if tail.empty?
                if Listing::canBeDefault(tail.first) then
                    head = head + Pure::energy(tail.first)
                    tail = tail.drop(1)
                    break
                else
                    head = head + tail.take(1)
                    tail = tail.drop(1)
                end
            }
            items = head + tail
            items
                .each{|item|
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
