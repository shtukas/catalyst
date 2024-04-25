
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

class MainUserInterface

    # -----------------------------------------
    # Data

    # MainUserInterface::listable(item)
    def self.listable(item)
        return true if NxBalls::itemIsActive(item)
        return false if !DoNotShowUntil2::isVisible(item)
        true
    end

    # MainUserInterface::canBeDefault(item)
    def self.canBeDefault(item)
        return false if TmpSkip1::isSkipped(item)
        return true if NxBalls::itemIsRunning(item)
        return false if !DoNotShowUntil2::isVisible(item)
        return false if TmpSkip1::isSkipped(item)
        true
    end

    # MainUserInterface::isInterruption(item)
    def self.isInterruption(item)
        item["interruption"]
    end

    # MainUserInterface::toString2(store, item, context = nil)
    def self.toString2(store, item, context = nil)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : ""
        arrow = item["x:prefix:0859"] ? " (#{item["x:prefix:0859"]})" : ""
        line = "#{storePrefix} #{arrow} #{PolyFunctions::toString(item, context)}#{TxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil2::suffixString(item)}#{Catalyst::donationSuffix(item)}"

        if !DoNotShowUntil2::isVisible(item) and !NxBalls::itemIsActive(item) then
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

    # MainUserInterface::items()
    def self.items()
        [
            NxBalls::activeItems(),
            DropBox::items(),
            Desktop::muiItems(),
            Anniversaries::muiItems(),
            Config::isPrimaryInstance() ? PhysicalTargets::muiItems() : [],
            Waves::muiItemsInterruption(),
            NxOndates::muiItems(),
            NxBackups::muiItems(),
            NxFloats::muiItems(),
            NxBufferInMonitors::muiItems(),
            NxTodos::muiItems(),
            NxThreads::muiItems1(),
            Waves::muiItemsNotInterruption(),
            NxThreads::muiItems2(),
        ]
            .flatten
            .select{|item| MainUserInterface::listable(item) }
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
    end

    # MainUserInterface::applyNxBallOrdering(items)
    def self.applyNxBallOrdering(items)
        activeItems, nonActiveItems = items.partition{|item| NxBalls::itemIsActive(item) }
        runningItems, pausedItems = activeItems.partition{|item| NxBalls::itemIsRunning(item) }
        runningItems + pausedItems + nonActiveItems
    end

    # MainUserInterface::items2()
    def self.items2()
        items = MainUserInterface::items()
        items = MainUserInterface::applyNxBallOrdering(items)
        items = Prefix::addPrefix(items)
        items
            .select{|item| MainUserInterface::listable(item) }
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

    # MainUserInterface::speedTest()
    def self.speedTest()

        spot = Speedometer.new()

        spot.start_contest()
        spot.contest_entry("Anniversaries::muiItems()", lambda { Anniversaries::muiItems() })
        spot.contest_entry("DropBox::items()", lambda { DropBox::items() })
        spot.contest_entry("NxBalls::activeItems()", lambda{ NxBalls::activeItems() })
        spot.contest_entry("PhysicalTargets::muiItems()", lambda{ PhysicalTargets::muiItems() })
        spot.contest_entry("Waves::muiItems()", lambda{ Waves::muiItems() })
        spot.end_contest()

        puts ""

        spot.start_unit("MainUserInterface::items()")
        MainUserInterface::items()
        spot.end_unit()

        spot.start_unit("MainUserInterface::items().first(100) >> MainUserInterface::toString2(store, item)")
        store = ItemStore.new()
        items = MainUserInterface::items().first(100)
        items.each {|item| MainUserInterface::toString2(store, item) }
        spot.end_unit()

        spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
        store = ItemStore.new()

        LucilleCore::pressEnterToContinue()
    end

    # MainUserInterface::checkForCodeUpdates()
    def self.checkForCodeUpdates()
        if CommonUtils::isOnline() and (CommonUtils::localLastCommitId() != CommonUtils::remoteLastCommitId()) then
            puts "Attempting to download new code"
            output = `#{File.dirname(__FILE__)}/../pull-from-origin`.strip
            return (output == "Already up to date.")
        end
        false
    end

    # MainUserInterface::injectActiveItems(items, runningItems)
    def self.injectActiveItems(items, runningItems)
        activeItems, pausedItems = runningItems.partition{|item| NxBalls::itemIsRunning(item) }
        activeItems + pausedItems + items
    end

    # MainUserInterface::main()
    def self.main()
        initialCodeTrace = CommonUtils::catalystTraceCode()
        loop {
            MainUserInterface::listing(initialCodeTrace)
        }
    end

    # MainUserInterface::listing(initialCodeTrace)
    def self.listing(initialCodeTrace)
        loop {

            if CommonUtils::catalystTraceCode() != initialCodeTrace then
                puts "Code change detected"
                exit
            end

            if Config::isPrimaryInstance() and ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 3600)  then
                Catalyst::periodicPrimaryInstanceMaintenance()
            end

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
            store = ItemStore.new()

            system("clear")

            spacecontrol.putsline ""

            items = MainUserInterface::items2()

            uuids = JSON.parse(XCache::getOrDefaultValue("43ef5eda-d16d-483f-a438-e98d437bedda", "[]"))
            if uuids.size > 0 then
                uuids.each{|uuid|
                    item = Cubes2::itemOrNull(uuid)
                    next if item.nil?
                    puts "[selected] #{PolyFunctions::toString(item)}"
                }
                puts ""
            end

            items
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    line = MainUserInterface::toString2(store, item, "main-listing-1635")
                    status = spacecontrol.putsline line
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            if input == "exit" then
                XCache::set("a297793a-a62e-4e2f-b7aa-72d494bdb206", "focus")
                return
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
