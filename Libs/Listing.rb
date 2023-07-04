

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

        return false if item["mikuType"] == "DesktopTx1"
        if item["mikuType"] == "NxCollection" then
            return TxEngines::compositeCompletionRatio(item["engine"])
        end

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
        [
            Anniversaries::listingItems(),
            PhysicalTargets::listingItems(),
            Waves::listingItems().select{|item| item["interruption"] },
            NxBackups::listingItems(),
            DarkEnergy::mikuType("NxFront"),
            DxAntimatters::listingItems(),
            NxOndates::listingItems(),
            Waves::listingItems().select{|item| !item["interruption"] },
            NxCollections::listingItems(),
            NxTasks::listingItems()
        ]
            .flatten
            .select{|item| Listing::listable(item) }
    end

    # Listing::itemToString1(item)
    def self.itemToString1(item)
        if item["mikuType"] == "NxTask" then
            return NxTasks::toStringForMainListing(item)
        end
        PolyFunctions::toString(item)
    end

    # Listing::toString2(store, item)
    def self.toString2(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        str1 = Listing::itemToString1(item)

        ordinalSuffix = ListingPositions::getOrNull(item) ? " (#{"%5.2f" % ListingPositions::getOrNull(item)})" : ""

        line = "#{storePrefix}#{ordinalSuffix} #{str1}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DxNotes::toStringSuffix(item)}#{DoNotShowUntil::suffixString(item)}#{TmpSkip1::skipSuffix(item)}"

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
        spot.contest_entry("DarkEnergy::mikuType(NxFront)", lambda{ DarkEnergy::mikuType("NxFront") })
        spot.contest_entry("Listing::maintenance()", lambda{ Listing::maintenance() })
        spot.contest_entry("NxBalls::runningItems()", lambda{ NxBalls::runningItems() })
        spot.contest_entry("NxBackups::listingItems()", lambda{ NxBackups::listingItems() })
        spot.contest_entry("DarkEnergy::mikuType(NxFront)", lambda{ DarkEnergy::mikuType("NxFront") })
        spot.contest_entry("NxOndates::listingItems()", lambda{ NxOndates::listingItems() })
        spot.contest_entry("NxTasks::listingItems()", lambda{ NxTasks::listingItems() })
        spot.contest_entry("NxTimes::itemsWithPendingTime()", lambda{ NxTimes::itemsWithPendingTime() })
        spot.contest_entry("NxTimes::listingItems()", lambda{ NxTimes::listingItems() })
        spot.contest_entry("PhysicalTargets::listingItems()", lambda{ PhysicalTargets::listingItems() })
        spot.contest_entry("Waves::listingItems()", lambda{ Waves::listingItems() })
        spot.contest_entry("TheLine::line()", lambda{ TheLine::line() })
        spot.end_contest()

        puts ""

        spot.start_unit("Listing::maintenance()")
        Listing::maintenance()
        spot.end_unit()

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
             PositiveSpace::maintenance()
             Bank::fileManagement()
             NxBackups::maintenance()
             NxCores::maintenance() # core maintenance
             NxCores::maintenance3() # DxAntimatter issue
             DxAntimatters::maintenance()
             NxTasks::maintenance()
             NxPages::maintenance()
             NxCollections::maintenance()
        end
        NxCores::maintenance2() # padding
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

            items = []

            items = Listing::items()
            ListingPositions::extractRangeFromListingItems(items)

            # ---------------------------------------------------------------------
            # We have the items, we destroy the positions of items from the previous run that are not in this run 
            # (in particular forgetting the position of waves)
            JSON.parse(XCache::getOrDefaultValue("ce9a54b7-a32d-4f41-b315-f79baaa2bb08", "[]"))
                .select{|i1| items.none?{|i2| i2["uuid"] == i1["uuid"] }}
                .each{|item| ListingPositions::revoke(item) }
            XCache::set("ce9a54b7-a32d-4f41-b315-f79baaa2bb08", JSON.generate(items))
            # ---------------------------------------------------------------------

            iris, positioned = items.partition{|item| ListingPositions::getOrNullForListing(item).nil? }
            positioned = positioned.sort_by{|item| ListingPositions::getOrNull(item) }

            # ---------------------------------------------------------------------
            # Shifting the position if too high
            if ListingPositions::getOrNull(positioned[0]) >= 10 then
                positioned.each{|item|
                    ListingPositions::set(item, ListingPositions::getOrNull(item)-10)
                }
            end
            # ---------------------------------------------------------------------

            # ---------------------------------------------------------------------
            # Shifting the position if too low
            if ListingPositions::getOrNull(positioned[0]) <= -10 then
                positioned.each{|item|
                    ListingPositions::set(item, ListingPositions::getOrNull(item)+10)
                }
            end
            # ---------------------------------------------------------------------

            system("clear")

            spacecontrol.putsline ""

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


            (iris+positioned)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::toString2(store, item)
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            
            if Float(input, exception: false) and ListingPositions::getOrNull(store.getDefault()).nil? then
                ListingPositions::set(store.getDefault(), input.to_f)
                next
            end

            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end
