
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
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil::suffixString(item)}#{Catalyst::donationSuffix(item)}#{TxCores::suffix(item)}"

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

    # Listing::isParentChild(item1, item2)
    def self.isParentChild(item1, item2)
        item1["uuid"] == item2["coreX-2137"]
    end

    # Listing::ensureChildrenComeBeforeParents(array1, array2)
    def self.ensureChildrenComeBeforeParents(array1, array2)
        if array2.empty? then
            return array1
        end
        if array1.empty? then
            x = array2.shift
            return Listing::ensureChildrenComeBeforeParents([x], array2)
        end
        x = array1.pop
        if array2.any?{|i| Listing::isParentChild(x, i) } then
            ys, array2 = array2.partition{|i| Listing::isParentChild(x, i) }
            return Listing::ensureChildrenComeBeforeParents(array1 + ys + [x], array2)
        else
            y = array2.shift
            return Listing::ensureChildrenComeBeforeParents(array1 + [x] + [y], array2)
        end
    end

    # Listing::items()
    def self.items()
        items = [
            DropBox::items(),
            Desktop::listingItems(),
            Anniversaries::listingItems(),
            PhysicalTargets::listingItems(),
            Waves::listingItems().select{|item| item["interruption"] },
            Waves::listingItems().select{|item| !item["interruption"] },
            Config::isPrimaryInstance() ? Backups::listingItems() : [],
            NxOndates::listingItems(),
            NxOpenCycleAutos::listingItems(),
            NxTasks::unattached(),
            TxCores::listingItems(),
            TxEngines::listingItems()
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

        i1, i2 = items.partition{|item| item["engine-0916"].nil? }

        i2, i3 = i2.partition{|item| TxEngines::dayCompletionRatio(item["engine-0916"]) < 1 }

        i2 = i2
            .sort_by{|item| TxEngines::dayCompletionRatio(item["engine-0916"]) }
        i2 = Listing::ensureChildrenComeBeforeParents([], i2)

        i3 = i3
            .sort_by{|item| TxEngines::dayCompletionRatio(item["engine-0916"]) }

        # i1: non engine items
        # i2: engined items less than 1 in order, with kids coming before their parents.
        # i3: engined items more than 1 in order

        i1 + i2 + i3
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
        spot.contest_entry("NxOndates::listingItems()", lambda{ NxOndates::listingItems() })
        spot.contest_entry("NxTasks::unattached()", lambda{ NxTasks::unattached() })
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

    # Listing::injectMissingRunningItems(items, runningItems)
    def self.injectMissingRunningItems(items, runningItems)
        if runningItems.empty? then
            return items
        else
            if items.take(20).map{|i| i["uuid"] }.include?(runningItems[0]["uuid"]) then
                return Listing::injectMissingRunningItems(items, runningItems.drop(1))
            else
                return Listing::injectMissingRunningItems(runningItems.take(1) + items, runningItems.drop(1))
            end
        end
    end

    # Listing::main()
    def self.main()

        initialCodeTrace = CommonUtils::catalystTraceCode()

        latestCodeTrace = initialCodeTrace

        $DataCenterCatalystItems = JSON.parse(XCache::getOrDefaultValue("1a777efb-c8a3-47d0-bf9f-67acecf06dc6", "{}"))
        $DataCenterListingItems = JSON.parse(XCache::getOrDefaultValue("6d02e327-e07a-4168-be13-d9e7f367c6f8", "{}"))

        Thread.new {
            loop {
                sleep 10

                data = {}
                Cubes::items()
                    .each{|item|
                        data[item["uuid"]] = item
                    }
                $DataCenterCatalystItems = data
                XCache::set("1a777efb-c8a3-47d0-bf9f-67acecf06dc6", JSON.generate($DataCenterCatalystItems))

                data = {} 
                Listing::items()
                    .first(50)
                    .each{|item|
                        data[item["uuid"]] = item
                    }
                $DataCenterListingItems = data
                XCache::set("6d02e327-e07a-4168-be13-d9e7f367c6f8", JSON.generate($DataCenterListingItems))

                sleep 1200
            }
        }

        loop {

            if CommonUtils::catalystTraceCode() != initialCodeTrace then
                puts "Code change detected"
                exit
            end

            if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 3600) then
                Catalyst::listing_maintenance()
            end

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
            store = ItemStore.new()

            items = $DataCenterListingItems.values.select{|item| Listing::listable(item) }
            items = Listing::injectMissingRunningItems(items, NxBalls::activeItems())
            items = items
                        .map{|item| Prefix::prefix([item]) }
                        .flatten

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
