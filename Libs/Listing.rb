
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
        return false if !DoNotShowUntil1::isVisible(item)
        return false if (item["onlyOnDays"] and !item["onlyOnDays"].include?(CommonUtils::todayAsLowercaseEnglishWeekDayName()))
        true
    end

    # Listing::canBeDefault(item)
    def self.canBeDefault(item)
        return false if TmpSkip1::isSkipped(item)
        return true if NxBalls::itemIsRunning(item)
        return false if !DoNotShowUntil1::isVisible(item)
        return false if TmpSkip1::isSkipped(item)
        return false if item["mikuType"] == "TxCondition"
        true
    end

    # Listing::isInterruption(item)
    def self.isInterruption(item)
        item["interruption"]
    end

    # Listing::toString2(store, item, context = nil)
    def self.toString2(store, item, context = nil)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "      "
        line = "#{storePrefix} #{PolyFunctions::toString(item, context)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil1::suffixString(item)}#{Catalyst::donationSuffix(item)}"

        if !DoNotShowUntil1::isVisible(item) and !NxBalls::itemIsActive(item) then
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
        i1s = [
            {
                "items" => Waves::muiItemsNotInterruption(),
                "rt"    => Bank1::recoveredAverageHoursPerDay("Waves:NotInterruption:7514-469a98")
            },
            {
                "items" => NxTasks::tail0(5),
                "rt"    => Bank1::recoveredAverageHoursPerDay("Tasks:0:81be93ef-0cdd-49db-9fb8-b83d6b57f606")
            },
            {
                "items" => NxTasks::tail1(5),
                "rt"    => Bank1::recoveredAverageHoursPerDay("Tasks:1:fdf0cb3b-58bd-4c83-af46-9479c361c9c7")
            }
        ].sort_by{|packet| packet["rt"] }.map{|packet| packet["items"] }.flatten
        [
            Anniversaries::listingItems(),
            Waves::muiItemsInterruption(),
            NxFloats::listingItems(),
            DropBox::items(),
            Desktop::listingItems(),
            NxBackups::listingItems(),
            NxTasks::managed(),
            NxTasks::dated(),
            i1s
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

    # -----------------------------------------
    # Ops

    # Listing::speedTest()
    def self.speedTest()

        spot = Speedometer.new()

        spot.start_contest()
        spot.contest_entry("NxBalls::activeItems()", lambda{ NxBalls::activeItems() })
        spot.contest_entry("DropBox::items()", lambda { DropBox::items() })
        spot.contest_entry("Desktop::listingItems()", lambda { Desktop::listingItems() })
        spot.contest_entry("Anniversaries::listingItems()", lambda { Anniversaries::listingItems() })
        spot.contest_entry("Waves::muiItemsInterruption()", lambda{ Waves::muiItemsInterruption() })
        spot.contest_entry("NxTasks::dated()", lambda{ NxTasks::dated() })
        spot.contest_entry("NxTasks::managed()", lambda{ NxTasks::managed() })
        spot.contest_entry("NxTasks::tail0(10)", lambda{ NxTasks::tail0(10) })
        spot.contest_entry("NxTasks::tail1(10)", lambda{ NxTasks::tail1(10) })
        spot.contest_entry("NxBackups::listingItems()", lambda{ NxBackups::listingItems() })
        spot.contest_entry("NxFloats::listingItems()", lambda{ NxFloats::listingItems() })
        spot.contest_entry("Waves::muiItemsNotInterruption()", lambda{ Waves::muiItemsNotInterruption() })
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

        LucilleCore::pressEnterToContinue()
    end

    # Listing::checkForCodeUpdates()
    def self.checkForCodeUpdates()
        if CommonUtils::isOnline() and (CommonUtils::localLastCommitId() != CommonUtils::remoteLastCommitId()) then
            puts "Attempting to download new code"
            output = `#{File.dirname(__FILE__)}/../pull-from-origin`.strip
            return (output == "Already up to date.")
        end
        false
    end

    # Listing::listing(initialCodeTrace)
    def self.listing(initialCodeTrace)
        loop {

            if CommonUtils::catalystTraceCode() != initialCodeTrace then
                puts "Code change detected"
                exit
            end

            if Config::isPrimaryInstance() then
                Items::processJournal()
                Bank1::processJournal()
                DoNotShowUntil1::processJournal()
            end

            if Config::isPrimaryInstance() and ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 86400) then
                Catalyst::periodicPrimaryInstanceMaintenance()
            end

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
            store = ItemStore.new()

            system("clear")

            items = Listing::items()

            items = items.take(10) + NxBalls::activeItems() + items.drop(10)

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
                    line = Listing::toString2(store, item, "main-listing-1315")
                    status = spacecontrol.putsline line
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            if input == "exit" then
                return
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Listing::main()
    def self.main()
        initialCodeTrace = CommonUtils::catalystTraceCode()
        Thread.new {
            loop {
                (lambda {
                    return if !NxBalls::shouldNotify()
                    CommonUtils::onScreenNotification("Catalyst", "running ball is over running")
                }).call()
                sleep 120
            }
        }
        loop {
            Listing::listing(initialCodeTrace)
        }
    end
end
