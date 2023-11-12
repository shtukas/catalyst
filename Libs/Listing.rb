
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
        return false if TmpSkip1::isSkipped(item)
        return true if NxBalls::itemIsRunning(item)
        return false if !DoNotShowUntil::isVisible(item)
        return false if TmpSkip1::isSkipped(item)
        true
    end

    # Listing::isInterruption(item)
    def self.isInterruption(item)
        item["interruption"]
    end

    # Listing::toString2(store, item)
    def self.toString2(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil::suffixString(item)}#{OpenCycles::suffix(item)}#{Catalyst::donationpSuffix(item)}"

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

    # Listing::trajectoryToPosition(trajectory)
    def self.trajectoryToPosition(trajectory)
        # ListingTrajectory 
        #     unixtime : float, unixtime
        #     speed    : float, 0.1 per hour
        trajectory["speed"] * (Time.new.to_f-trajectory["unixtime"]).to_f/3600
    end

    # Listing::itemToSpeed(item)
    def self.itemToSpeed(item)
        # ListingTrajectory 
        #     unixtime : float, unixtime
        #     speed    : float, 0.1 per hour
        if item["mikuType"] == "NxTask" and item["engine-0916"] then
            return 2
        end
        if item["mikuType"] == "NxTask" and !item["engine-0916"] then
            return 1
        end
        if item["mikuType"] == "NxOndate" then
            return 2
        end
        if item["mikuType"] == "TxCore" then
            return 1
        end
        if item["mikuType"] == "Wave" and item["interruption"] then
            return 4
        end
        if item["mikuType"] == "Wave" and !item["interruption"] then
            return 0.2
        end
        if item["mikuType"] == "PhysicalTarget" then
            return 5
        end
        raise "(error: 86a7-50641e6a2f7d) I don't know how to compute the speed for miku type: #{item["mikuType"]}"
    end

    # Listing::itemToTrajectory(item)
    def self.itemToTrajectory(item)
        # ListingTrajectory 
        #     unixtime : float, unixtime
        #     speed    : float, 0.1 per hour
        return item["trajectory"] if item["trajectory"]
        item = Catalyst::itemOrNull(item["uuid"])
        return item["trajectory"] if item["trajectory"]
        trajectory = {
            "unixtime" => Time.new.to_f,
            "speed"    => Listing::itemToSpeed(item)
        }
        puts "New trajectory for '#{PolyFunctions::toString(item)}': #{trajectory}"
        Updates::itemAttributeUpdate(item["uuid"], "trajectory", trajectory)
        trajectory
    end

    # Listing::items()
    def self.items()
        items = [
            DropBox::items(),
            Desktop::listingItems(),
            NxLifters::listingItems(),
            PhysicalTargets::listingItems(),
            Anniversaries::listingItems(),
            Waves::listingItems().select{|item| item["interruption"] },
            Config::isPrimaryInstance() ? Backups::listingItems() : [],
            NxOndates::listingItems(),
            NxTasks::orphansNonEngined(),
            TxEngines::listingItems(),
            TxCores::listingItems(),
            Waves::listingItems().select{|item| !item["interruption"] }
        ]
            .flatten
            .reject{|item| item["mikuType"] == "NxThePhantomMenace" }
            .select{|item| Listing::listable(item) }
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
            .sort_by{|item| Listing::trajectoryToPosition(Listing::itemToTrajectory(item)) }
            .reverse

        return items if items.size > 0

        Catalyst::mikuType("TxCore")
            .select{|item| Listing::listable(item) }
            .sort_by{|core| TxEngines::periodCompletionRatio(core["engine-0916"]) }
    end

    # -----------------------------------------
    # Ops

    # Listing::speedTest()
    def self.speedTest()

        spot = Speedometer.new()

        spot.start_contest()
        spot.contest_entry("Anniversaries::listingItems()", lambda { Anniversaries::listingItems() })
        spot.contest_entry("DropBox::items()", lambda { DropBox::items() })
        spot.contest_entry("NxBalls::runningItems()", lambda{ NxBalls::runningItems() })
        spot.contest_entry("NxOndates::listingItems()", lambda{ NxOndates::listingItems() })
        spot.contest_entry("NxTasks::orphansEngined()", lambda{ NxTasks::orphansEngined() })
        spot.contest_entry("NxTasks::orphansNonEngined()", lambda{ NxTasks::orphansNonEngined() })
        spot.contest_entry("TxCores::listingItems()", lambda{ TxCores::listingItems() })
        spot.contest_entry("PhysicalTargets::listingItems()", lambda{ PhysicalTargets::listingItems() })
        spot.contest_entry("Waves::listingItems()", lambda{ Waves::listingItems() })
        spot.end_contest()

        puts ""

        spot.start_unit("Listing::items()")
        Listing::items()
        spot.end_unit()

        spot.start_unit("Listing::items().first(100) >> Listing::toString2(store, item)")
        store = ItemStore.new()
        items = Listing::items().first(100)
        items.each {|item| Listing::toString2(store, item) }
        spot.end_unit()

        spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
        store = ItemStore.new()

        LucilleCore::pressEnterToContinue()
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

    # Listing::injectRunningItems(items, runningItems)
    def self.injectRunningItems(items, runningItems)
        if runningItems.empty? then
            return items
        else
            if items.take(20).map{|i| i["uuid"] }.include?(runningItems[0]["uuid"]) then
                return Listing::injectRunningItems(items, runningItems.drop(1))
            else
                return Listing::injectRunningItems(runningItems.take(1) + items, runningItems.drop(1))
            end
        end
    end

    # Listing::main()
    def self.main()

        initialCodeTrace = CommonUtils::catalystTraceCode()

        latestCodeTrace = initialCodeTrace

        loop {

            if CommonUtils::catalystTraceCode() != initialCodeTrace then
                puts "Code change detected"
                exit
            end

            EventsTimelineProcessor::procesLine()

            if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 3600) then
                Catalyst::listing_maintenance()
            end

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
            store = ItemStore.new()

            items = Prefix::prefix(Listing::injectRunningItems(Ox1s::organiseListing(Listing::items()), NxBalls::runningItems()))
                        .reject{|item| item["mikuType"] == "NxThePhantomMenace" }

            system("clear")

            spacecontrol.putsline ""

            items
                .reduce([]){|selected, item|
                    if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                        selected
                    else
                        selected + [item]
                    end
                }
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    line = Listing::toString2(store, item)
                    status = spacecontrol.putsline line
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"

            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end
