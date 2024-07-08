
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
        arrow = item["x:position"] ? " (#{"%4.2f" % item["x:position"]})" : ""
        line = "#{storePrefix}#{arrow} #{PolyFunctions::toString(item, context)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil1::suffixString(item)}#{Catalyst::donationSuffix(item)}#{Cx11s::suffix(item)}"

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

    # Listing::position(item)
    def self.position(item)
        if item["mikuType"] == "NxAnniversary" then
            return 0.1
        end
        if item["mikuType"] == "PhysicalTarget" then
            return 0.2
        end
        if item["mikuType"] == "Wave" and item["interruption"] then
            return 0.3
        end
        if item["mikuType"] == "NxOndate" then
            return 0.4
        end
        if item["mikuType"] == "NxFloat" then
            return 0.5
        end
        if item["mikuType"] == "NxBackup"then
            return 0.6
        end
        if item["mikuType"] == "NxTask" then
            return 0.7
        end
        if item["mikuType"] == "Wave" and !item["interruption"] then
            return 0.8
        end
        if item["mikuType"] == "TxCore" then
            return 0.5 + 0.5 * TxCores::ratio(item)
        end
        raise "Listing::position: I do not know how to position: #{item}"
    end

    # Listing::items()
    def self.items()
        [
            DropBox::items(),
            Desktop::listingItems(),
            Anniversaries::listingItems(),
            PhysicalTargets::listingItems(),
            Waves::muiItemsInterruption(),
            NxOndates::listingItems(),
            NxBackups::listingItems(),
            NxFloats::listingItems(),
            Waves::muiItemsNotInterruption(),
            TxCores::listingItems()
        ]
            .flatten
            .select{|item| Listing::listable(item) }
            .sort_by{|item| Listing::position(item) }
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
    end

    # Listing::applyNxBallOrdering(items)
    def self.applyNxBallOrdering(items)
        activeItems, nonActiveItems = items.partition{|item| NxBalls::itemIsActive(item) }
        runningItems, pausedItems = activeItems.partition{|item| NxBalls::itemIsRunning(item) }
        runningItems + pausedItems + nonActiveItems
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
        spot.contest_entry("PhysicalTargets::listingItems()", lambda{ PhysicalTargets::listingItems() })
        spot.contest_entry("Waves::muiItemsInterruption()", lambda{ Waves::muiItemsInterruption() })
        spot.contest_entry("NxOndates::listingItems()", lambda{ NxOndates::listingItems() })
        spot.contest_entry("NxBackups::listingItems()", lambda{ NxBackups::listingItems() })
        spot.contest_entry("NxFloats::listingItems()", lambda{ NxFloats::listingItems() })
        spot.contest_entry("TxCores::listingItems()", lambda{ TxCores::listingItems() })
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

    # Listing::injectActiveItems(items, runningItems)
    def self.injectActiveItems(items, runningItems)
        activeItems, pausedItems = runningItems.partition{|item| NxBalls::itemIsRunning(item) }
        activeItems + pausedItems + items
    end

    # Listing::main()
    def self.main()
        initialCodeTrace = CommonUtils::catalystTraceCode()
        loop {
            Listing::listing(initialCodeTrace)
        }
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

            txConditions = TxConditions::listingItems(items)
            if txConditions.size > 0 then
                spacecontrol.putsline ""
                txConditions
                    .each{|item|
                        store.register(item, Listing::canBeDefault(item))
                        line = Listing::toString2(store, item)
                        spacecontrol.putsline line
                    }
            end

            spacecontrol.putsline ""

            Prefix::addPrefix(NxBalls::activeItems() + items.select{|item| Cx11s::itemShouldBeListed(item) })
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
end
