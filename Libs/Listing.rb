
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
        arrow = (item["lpx01"] and item["lpx01"]["position"]) ? " [#{"%7.2f" % item["lpx01"]["position"]}]" : "          "
        line = "#{storePrefix}#{arrow} #{PolyFunctions::toString(item, context)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil1::suffixString(item)}#{Catalyst::donationSuffix(item)}"

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
        items = [
            DropBox::items(),
            Desktop::listingItems(),
            Anniversaries::listingItems(),
            TargetNumbers::listingItems(),
            Waves::muiItemsInterruption(),
            NxOndates::listingItems(),
            NxBackups::listingItems(),
            NxFloats::listingItems(),
            Waves::muiItemsNotInterruption1(),
            NxMiniProjects::listingItems(),
            TxCores::listingItems(),
            Waves::muiItemsNotInterruption2(),
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
    # Data LPx01

    # Listing::computeLPx01(items, cursor)
    def self.computeLPx01(items, cursor)

        # The expectation is that all items have a valid (present and carrying 
        # today's date) LPx01, and are given in the position's order 
        # and that the cursor doesn't have one valid LPx01, but the cursor 
        # could already have a LPx01 issued on a previous day

        if items.any?{|item| item["lpx01"].nil? } then
            raise "(error: 87d2b22a) I can't Listing::computeLPx01 on the input given"
        end

        if cursor["lpx01"] and cursor["lpx01"]["date"] == CommonUtils::today() then
            raise "(error: 2d39) I can't Listing::computeLPx01 on the input given"
        end

        if items.size == 0 then
            # If the cursor already had a LPx01 (necessarily from a previous date), 
            # we just override it.
            return {
                "date" => CommonUtils::today(),
                "position" => 1
            }
        end

        firstPosition = items.first["lpx01"]["position"] 
        lastPosition = items.last["lpx01"]["position"] 

        if cursor["mikuType"] == "NxAnniversary" then
            # We want to put the anniversary just after the third item
            # between the third and the forth
            items.shift
            items.shift
            return {
                "date" => CommonUtils::today(),
                "position" => 0.5*(items[0]["lpx01"]["position"] + items[1]["lpx01"]["position"])
            }
        end

        if cursor["mikuType"] == "Wave" and cursor["interruption"] then
            return {
                "date" => CommonUtils::today(),
                "position" => 0.5 * firstPosition
            }
        end

        if cursor["mikuType"] == "Wave" and !cursor["interruption"] then
            if cursor["lpx01"] then
                # We are just updating the date but keeping the same position
                return {
                    "date" => CommonUtils::today(),
                    "position" => cursor["lpx01"]["position"]
                }
            end
            return {
                "date" => CommonUtils::today(),
                "position" => (lastPosition + 1).floor
            }
        end

        if cursor["lpx01"] then
            return {
                "date" => CommonUtils::today(),
                "position" => cursor["lpx01"]["position"]
            }
        end

        loop {
            break if items.none?{|item| item["mikuType"] == cursor["mikuType"] }
            items.shift # removing the first item
        }
        # At this point there is no cursor["mikuType"] in the list of items

        if items.size < 4 then
            return {
                "date" => CommonUtils::today(),
                "position" => (lastPosition + 1).floor
            }
        end

        # We now put the item as the new position 4 of the tail.

        items.shift
        items.shift

        {
            "date" => CommonUtils::today(),
            "position" => 0.5*(items[0]["lpx01"]["position"] + items[1]["lpx01"]["position"])
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
        spot.contest_entry("TargetNumbers::listingItems()", lambda{ TargetNumbers::listingItems() })
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

            spacecontrol.putsline ""

            loop {
                items = Listing::items()
                break if items.all?{|item| item["lpx01"] and item["lpx01"]["date"] == CommonUtils::today() } 
                items1, items2 = items.partition{|item| item["lpx01"] and item["lpx01"]["date"] == CommonUtils::today() }
                items1 = items1.sort_by{|item| item["lpx01"]["position"] }
                cursor = items2.first
                lpx01 = Listing::computeLPx01(items1, cursor)
                Items::setAttribute(cursor["uuid"], "lpx01", lpx01)
            }

            items = Listing::items()
            items = items.sort_by{|item| item["lpx01"]["position"] }
            items = items.take(10) + NxBalls::activeItems() + items.drop(10)
            items

            cx04s = Cx04::cx04s(items)
            if !cx04s.empty? then
                cx04s.each{|item|
                    store.register(item, false)
                    line = Listing::toString2(store, item, "main-listing-1315")
                    status = spacecontrol.putsline line
                }
                spacecontrol.putsline ""
            end

            items = items.select{|item| item["cx04"].nil? }
            items = Prefix::addPrefix(items)
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
