# encoding: UTF-8

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

        return false if item["mikuType"] == "DesktopTx1"
        return false if item["mikuType"] == "NxFire"
        return false if (item["mikuType"] == "NxBurner" and !NxBurners::pendingAcknowledgement(item))

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

    # Listing::burnersAndFires()
    def self.burnersAndFires()

        burners = DarkEnergy::mikuType("NxBurner")

        fires = DarkEnergy::mikuType("NxFire")

        items = [
            Desktop::listingItems(),
            (burners + fires).sort_by{|item| item["unixtime"] }
        ]
            .flatten
            .select{|item| Listing::listable(item) }
            .reduce([]){|selected, item|
                if !selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected + [item]
                else
                    selected
                end
            }

        items
    end

    # Listing::items()
    def self.items()

        items = [
            NxBalls::runningItems(),
            Anniversaries::listingItems(),
            PhysicalTargets::listingItems(),
            Waves::listingItems().select{|item| item["interruption"] },
            NxBurners::listingItems(),
            NxBackups::listingItems(),
            DarkEnergy::mikuType("NxFire"),
            NxOndates::listingItems(),
            Waves::listingItems().select{|item| !item["interruption"] },
            NxDeadlines::listingItems(),
            NxEngines::listingItems(),
            DarkEnergy::mikuType("NxDrop"),
            Pure::pure(),
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

        if items.empty? then
            items = Pure::bottom()
        end

        if NxTimes::hasPendingTime() then
            NxTimes::listingItems() + items
        else
            items.take(1) + NxTimes::listingItems() + items.drop(1)
        end
    end

    # Listing::itemToListingLine(store, item)
    def self.itemToListingLine(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        str1 = PolyFunctions::toString(item)

        line = "#{storePrefix} #{str1}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{NxNotes::toStringSuffix(item)}#{DoNotShowUntil::suffixString(item)}#{TmpSkip1::skipSuffix(item)}#{NxCores::suffix(item)}"

        if !DoNotShowUntil::isVisible(item) and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if item["mikuType"] == "NxBurner" and !NxBurners::pendingAcknowledgement(item) then
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
        spot.contest_entry("DarkEnergy::mikuType(NxBurner)", lambda{ DarkEnergy::mikuType("NxBurner") })
        spot.contest_entry("DarkEnergy::mikuType(NxDrop)", lambda{ DarkEnergy::mikuType("NxDrop") })
        spot.contest_entry("DarkEnergy::mikuType(NxFire)", lambda{ DarkEnergy::mikuType("NxFire") })
        spot.contest_entry("Listing::burnersAndFires()", lambda{ Listing::burnersAndFires() })
        spot.contest_entry("Listing::maintenance()", lambda{ Listing::maintenance() })
        spot.contest_entry("NxBackups::listingItems()", lambda{ NxBackups::listingItems() })
        spot.contest_entry("NxDeadlines::listingItems()", lambda{ NxDeadlines::listingItems() })
        spot.contest_entry("NxEngines::listingItems()", lambda{ NxEngines::listingItems() })
        spot.contest_entry("NxOndates::listingItems()", lambda{ NxOndates::listingItems() })
        spot.contest_entry("NxTimes::hasPendingTime()", lambda{ NxTimes::hasPendingTime() })
        spot.contest_entry("NxTimes::listingItems()", lambda{ NxTimes::listingItems() })
        spot.contest_entry("PhysicalTargets::listingItems()", lambda{ PhysicalTargets::listingItems() })
        spot.contest_entry("Waves::listingItems()", lambda{ Waves::listingItems() })
        spot.contest_entry("TheLine::line()", lambda{ TheLine::line() })
        spot.end_contest()

        puts ""

        spot.start_unit("Listing::maintenance()")
        Listing::maintenance()
        spot.end_unit()

        spot.start_unit("pures")
        pures = Pure::pure()
        spot.end_unit()

        spot.start_unit("Listing::items()")
        items = Listing::items()
        spot.end_unit()

        spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
        store = ItemStore.new()

        spot.start_unit("Listing::printing")
        Listing::printing(spacecontrol, store, items)
        spot.end_unit()

        LucilleCore::pressEnterToContinue()
    end

    # Listing::maintenance()
    def self.maintenance()
        if Config::isPrimaryInstance() then
             PositiveSpace::maintenance()
             Bank::fileManagement()
             NxBackups::maintenance()
             NxBurners::maintenance()
             NxCores::maintenance_leader_instance()
             NxEngines::maintenance()
        end
        NxCores::maintenance_all_instances()
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

    # Listing::printing(spacecontrol, store, items)
    def self.printing(spacecontrol, store, items)
        spacecontrol.putsline ""
        items
            .each{|item|
                store.register(item, Listing::canBeDefault(item))
                status = spacecontrol.putsline Listing::itemToListingLine(store, item)
                break if !status
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

        initialCodeTrace = CommonUtils::stargateTraceCode()

        Thread.new {
            loop {
                Listing::checkForCodeUpdates()
                sleep 300
            }
        }

        loop {

            if CommonUtils::stargateTraceCode() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            Listing::maintenance()

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
            store = ItemStore.new()

            system("clear")

            Listing::printing(spacecontrol, store, Listing::items())

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            next if input == ""

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end
