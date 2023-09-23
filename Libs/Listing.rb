
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

        return false if item["mikuType"] == "TxCore"

        return false if item["mikuType"] == "DesktopTx1"

        return false if item["mikuType"] == "NxBurner"

        return false if item["mikuType"] == "NxPool"

        return false if !DoNotShowUntil::isVisible(item)

        return false if TmpSkip1::isSkipped(item)

        true
    end

    # Listing::isInterruption(item)
    def self.isInterruption(item)
        item["interruption"]
    end

    # Listing::itemsToCumulatedTodayTime(items)
    def self.itemsToCumulatedTodayTime(items)
        items.map{|item| Bank::getValueAtDate(item["uuid"], CommonUtils::today()) }.inject(0, :+)
    end

    # Listing::generatePriorities()
    def self.generatePriorities()
        XCache::set("8102-09aafb931f40:Listing::items_adhoc_today()", Listing::itemsToCumulatedTodayTime(Listing::items_adhoc_today()))
        XCache::set("8102-09aafb931f40:Listing::items_waves2()", Listing::itemsToCumulatedTodayTime(Listing::items_waves2()))
        XCache::set("8102-09aafb931f40:Listing::items_todo()", Listing::itemsToCumulatedTodayTime(Listing::items_todo()))
    end

    # Listing::items_adhoc_today()
    def self.items_adhoc_today()
        [
            Anniversaries::listingItems(),
            DropBox::items(),
            PhysicalTargets::listingItems(),
            Catalyst::mikuType("NxLine"),
            Waves::listingItems().select{|item| item["interruption"] },
            NxOndates::listingItems(),
            Backups::listingItems()
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
            .map{|item|
                InMemoryCache::set("block-attribution:4858-a4ce-ff9b44527809:#{item["uuid"]}", "block:adhoc-today:1b76c-4c041e05b55a")
                item
            }
    end

    # Listing::items_waves2()
    def self.items_waves2()
        Waves::listingItems().select{|item| !item["interruption"] }
            .select{|item| Listing::listable(item) }
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
            .map{|item|
                InMemoryCache::set("block-attribution:4858-a4ce-ff9b44527809:#{item["uuid"]}", "block:waves2:0111-1b76c-4c041e05b55a")
                item
            }
    end

    # Listing::items_todo()
    def self.items_todo()
        [
            NxBurners::listingItems(),
            Todos::bufferInItems(),
            Todos::drivenItems(),
            Todos::priorityItems(),
            TxCores::listingItems(),
            Todos::otherItems()
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
            .map{|item|
                InMemoryCache::set("block-attribution:4858-a4ce-ff9b44527809:#{item["uuid"]}", "block:todo:099111-1b76c-4c041e05b55a")
                item
            }
    end

    # Listing::items()
    def self.items()
        blocks = [
            {
                "items"     => Listing::items_adhoc_today(),
                "itemsmust" => Listing::items_adhoc_today().select{|item| NxBalls::itemIsActive(item) },
                "ordinal"   => Bank::getValueAtDate("block:adhoc-today:1b76c-4c041e05b55a",  CommonUtils::today()),
                "block"     => NxLambdas::make(SecureRandom.hex, "🫧 adhoc today (#{Bank::getValueAtDate("block:adhoc-today:1b76c-4c041e05b55a",  CommonUtils::today())})", lambda{
                    items = Listing::items_adhoc_today()
                    Dives::genericprogram(items)
                })
            },
            {
                "items"     => Listing::items_waves2(),
                "itemsmust" => Listing::items_waves2().select{|item| NxBalls::itemIsActive(item) },
                "ordinal"   => Bank::getValueAtDate("block:waves2:0111-1b76c-4c041e05b55a",  CommonUtils::today()),
                "block"     => NxLambdas::make(SecureRandom.hex, "🫧 wave2 (#{Bank::getValueAtDate("block:waves2:0111-1b76c-4c041e05b55a",  CommonUtils::today())})", lambda{
                    items = Listing::items_waves2()
                    Dives::genericprogram(items)
                })
            },
            {
                "items"     => Listing::items_todo(),
                "itemsmust" => Listing::items_todo().select{|item| NxBalls::itemIsActive(item) },
                "ordinal"   => Bank::getValueAtDate("block:todo:099111-1b76c-4c041e05b55a",  CommonUtils::today()),
                "block"     => NxLambdas::make(SecureRandom.hex, "🫧 todo (#{XCache::getOrDefaultValue("block:todo:099111-1b76c-4c041e05b55a", "0")})", lambda{
                    items = Listing::items_todo()
                    Dives::genericprogram(items)
                })
            }
        ]
            .sort_by{|block| block["ordinal"] }

        [
            blocks[0]["items"],
            blocks.drop(1).map{|block| block["itemsmust"] },
            blocks.map{|block| block["block"] },
        ]
            .flatten
    end

    # Listing::toString2(store, item)
    def self.toString2(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        s2 = item["list-ord-03"] ? "(#{"%.3f" % (item["list-ord-03"])})" : "       "
        line = "#{storePrefix} #{s2} #{PolyFunctions::toString(item)}#{PolyFunctions::lineageSuffix(item).yellow}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil::suffixString(item)}#{TmpSkip1::skipSuffix(item)}"

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

    # Listing::toString3(thread, store, item)
    def self.toString3(thread, store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        str1 = (lambda {|thread, item|
            if thread["sortType"] == "position-sort" and item["mikuType"] == "NxTask" then
                return NxTasks::toStringPosition(item)
            end
            if thread["sortType"] == "time-sort" and item["mikuType"] == "NxTask" then
                return NxTasks::toStringTime(item)
            end
            if thread["sortType"] == "position-sort" and item["mikuType"] == "NxThread" then
                return NxThreads::toStringPosition(item)
            end
            if thread["sortType"] == "time-sort" and item["mikuType"] == "NxThread" then
                return NxThreads::toStringTime(item)
            end
            PolyFunctions::toString(item)
        }).call(thread, item)

        line = "#{storePrefix} #{str1}#{PolyFunctions::lineageSuffix(item).yellow}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil::suffixString(item)}#{TmpSkip1::skipSuffix(item)}"

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
        spot.contest_entry("DropBox::items()", lambda{ DropBox::items() })
        spot.contest_entry("Catalyst::mikuType(NxLine)", lambda{ Catalyst::mikuType("NxLine") })
        spot.contest_entry("NxBalls::runningItems()", lambda{ NxBalls::runningItems() })
        spot.contest_entry("NxOndates::listingItems()", lambda{ NxOndates::listingItems() })
        spot.contest_entry("NxBurners::listingItems()", lambda{ NxBurners::listingItems() })
        spot.contest_entry("Todos::bufferInItems()", lambda{ Todos::bufferInItems() })
        spot.contest_entry("TxCores::listingItems()", lambda{ TxCores::listingItems() })
        spot.contest_entry("Todos::otherItems()", lambda{ Todos::otherItems() })
        spot.contest_entry("PhysicalTargets::listingItems()", lambda{ PhysicalTargets::listingItems() })
        spot.contest_entry("Waves::listingItems()", lambda{ Waves::listingItems() })

        spot.end_contest()

        puts ""

        spot.start_unit("Listing::maintenance()")
        Listing::maintenance()
        spot.end_unit()

        cores = Catalyst::mikuType("TxCore")
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
            puts "> Listing::maintenance() on primary instance"
            Bank::fileManagement()
            NxTasks::maintenance()
            Catalyst::maintenance()
            NxThreads::maintenance()
            TxCores::maintenance2()
            EventTimelineMaintenance::shortenToLowerPing()
            EventTimelineMaintenance::rewriteHistory()
        end
        TxCores::maintenance3()
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

    # Listing::removeLstOrd(item)
    def self.removeLstOrd(item)
        Events::publishItemAttributeUpdate(item["uuid"], "list-ord-03", nil)
    end

    # Listing::ordinalise(items)
    def self.ordinalise(items)
        if items.select{|item| item["list-ord-03"] }.any?{|item| item["list-ord-03"] < 0 } then
            lowerbound = items.select{|item| item["list-ord-03"] }.map{|item| item["list-ord-03"] }.min
            items = items
                        .select{|item| item["list-ord-03"] }
                        .map{|item|
                            value = item["list-ord-03"] + (-lowerbound)
                            item["list-ord-03"] = value
                            Events::publishItemAttributeUpdate(item["uuid"], "list-ord-03", value)
                            item
                        }
        end
        if items.select{|item| item["list-ord-03"] }.any?{|item| item["list-ord-03"] > 1 } then
            items = items
                        .select{|item| item["list-ord-03"] }
                        .map{|item|
                            value = item["list-ord-03"].to_f/2
                            item["list-ord-03"] = value
                            Events::publishItemAttributeUpdate(item["uuid"], "list-ord-03", value)
                            item
                        }
        end

        if items.select{|item| item["list-ord-03"] }.all?{|item| item["list-ord-03"] > 0.1 } then
            items = items
                        .select{|item| item["list-ord-03"] }
                        .map{|item|
                            value = item["list-ord-03"] - 0.1
                            item["list-ord-03"] = value
                            Events::publishItemAttributeUpdate(item["uuid"], "list-ord-03", value)
                            item
                        }
        end
        getRandom = lambda{|lowerbound, upperbound|
            lowerbound + rand*(upperbound-lowerbound)
        }
        itemToValue = lambda{|item|
            return getRandom.call(0.5, 1.0) if (item["mikuType"] == "Wave" and !item["interruption"])
            return getRandom.call(0.1, 0.2) if (item["mikuType"] == "Wave" and item["interruption"])
            return getRandom.call(0.2, 0.3) if item["mikuType"] == "NxOndate"
            return getRandom.call(0.3, 0.6) if item["mikuType"] == "NxThread"
            return getRandom.call(0.3, 0.6) if item["mikuType"] == "NxTask"
            return getRandom.call(0.5, 0.7) if item["mikuType"] == "TxCore"
            return getRandom.call(0.1, 0.2) if item["mikuType"] == "PhysicalTarget"
            return getRandom.call(0.1, 0.2) if item["mikuType"] == "Backup"
            return getRandom.call(0.05, 0.06) if item["mikuType"] == "NxAnniversary"
            return getRandom.call(0.99, 0.99) if item["mikuType"] == "NxLambda"
            raise "(error: cbbfa15a-6bff-4cac-a718-9906b69fb91e) Listing::ordinalise: unsupported mikuType: #{item["mikuType"]}"
        }
        items.reduce([]){|collection, item|
            if item["list-ord-03"].nil? then
                value = itemToValue.call(item)
                Events::publishItemAttributeUpdate(item["uuid"], "list-ord-03", value)
                item["list-ord-03"] = value
            end
            collection + [item]
        }
        items = items.sort_by{|item| item["list-ord-03"] }

        return [] if items.empty?
        # One last thing we do is publishing the two bonds 

        XCache::set("low:a0ce-6591a1ee9d5d", items.map{|item| item["list-ord-03"] }.min) 
        XCache::set("high:a0ce-6591a1ee9d5d", items.map{|item| item["list-ord-03"] }.max)

        items
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
                # Event Timeline
                EventTimelineReader::issueNewFSComputedTraceForCaching()
                EventTimelineMaintenance::publishPing()
                sleep 300
            }
        }

        Thread.new {
            loop {
                Listing::generatePriorities()
                sleep 120
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

            items = NxBalls::runningItems() + Listing::ordinalise(Listing::items())
            items = Prefix::prefix(items)

            # This last step is to remove duplicates due to running items
            items = items.reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }

            items
                .each{|item|
                    if item["mikuType"] == "TxEmpty" then
                        spacecontrol.putsline ""
                        next
                    end
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
