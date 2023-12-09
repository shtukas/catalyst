
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
        positionstr = Ox1::activePositionOrNull(item) ? "stack".red : "#{"%.3f" % Metrics::metric2(item)}"
        line = "#{storePrefix} #{positionstr}#{TxBoosters::suffix(item)} #{PolyFunctions::toString(item)}#{Notes::suffix(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil::suffixString(item)}#{Catalyst::donationSuffix(item)}"

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

    # Listing::items()
    def self.items()
        [
            Ox1::items(),
            DropBox::items(),
            Desktop::listingItems(),
            Anniversaries::listingItems(),
            PhysicalTargets::listingItems(),
            Waves::listingItems().select{|item| item["interruption"] },
            Config::isPrimaryInstance() ? Backups::listingItems() : [],
            NxOndates::listingItems(),
            NxStickies::listingItems(),
            NxTasks::boosted(),
            NxCruisers::listingItems(),
            Waves::listingItems().select{|item| !item["interruption"] },
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

    # Listing::items2()
    def self.items2()
        items = Listing::items()
        items = Metrics::order(Listing::items())
        items = Ox1::organiseListing(items)
        runningItems, pausedItems = NxBalls::activeItems().partition{|item| NxBalls::itemIsRunning(item) }
        items = runningItems + pausedItems + items
        items = Prefix::prefix(items)
        items
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
    end

    # -----------------------------------------
    # Ops

    # Listing::speedTest()
    def self.speedTest()

        spot = Speedometer.new()

        spot.start_contest()
        spot.contest_entry("Anniversaries::listingItems()", lambda { Anniversaries::listingItems() })
        spot.contest_entry("DropBox::items()", lambda { DropBox::items() })
        spot.contest_entry("NxBalls::activeItems()", lambda{ NxBalls::activeItems() })
        spot.contest_entry("NxCruisers::listingItems()", lambda{ NxCruisers::listingItems() })
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

    # Listing::checkForCodeUpdates()
    def self.checkForCodeUpdates()
        if CommonUtils::isOnline() and (CommonUtils::localLastCommitId() != CommonUtils::remoteLastCommitId()) then
            puts "Attempting to download new code"
            system("#{File.dirname(__FILE__)}/../pull-from-origin")
        end
    end

    # Listing::injectActiveItems(items, runningItems)
    def self.injectActiveItems(items, runningItems)
        activeItems, pausedItems = runningItems.partition{|item| NxBalls::itemIsRunning(item) }
        activeItems + pausedItems + items
    end

    # Listing::main()
    def self.main()

        initialCodeTrace = CommonUtils::catalystTraceCode()

        latestCodeTrace = initialCodeTrace

        DataCenter::reload()

        Thread.new {
            loop {
                sleep 1200
                DataCenter::reload()
            }
        }

        loop {

            if CommonUtils::catalystTraceCode() != initialCodeTrace then
                puts "Code change detected"
                exit
            end

            if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 3600) then
                Catalyst::periodicPrimaryInstanceMaintenance()
            end

            if Config::isPrimaryInstance() then
                Catalyst::openCyclesSync()
            end

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
            store = ItemStore.new()

            system("clear")

            spacecontrol.putsline ""

            Listing::items2()
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

    # Listing::focus()
    def self.focus()
        system('clear')
        loop {
            item = Listing::items2().first
            store = ItemStore.new()
            store.register(item, true)
            if NxBalls::itemIsRunning(item) then
                LucilleCore::pressEnterToContinue("#{Listing::toString2(store, item)} [#{"press to stop".green}] ")
                NxBalls::stop(item)
                if item["mikuType"] == "NxTask" then
                    if LucilleCore::askQuestionAnswerAsBoolean("done/destroy: '#{PolyFunctions::toString(item).green} ? '") then
                        PolyActions::destroy(item)
                    end
                    next
                end
                raise "I don't know how to end focus running of #{JSON.pretty_generate(item)}"
            end
            if NxBalls::itemIsActive(item) then
                # At this point we know it's paused
                LucilleCore::pressEnterToContinue("#{Listing::toString2(store, item)} [#{"press to pursue".green}] ")
                NxBalls::pursue(item)
                next
            end
            LucilleCore::pressEnterToContinue("#{Listing::toString2(store, item)} [#{"press to start".green}] ")
            PolyActions::start(item)
        }
    end
end
