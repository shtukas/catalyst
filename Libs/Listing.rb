class Listing

    # -----------------------------------------
    # Data

    # Listing::canBeDefault(item)
    def self.canBeDefault(item)
        return false if TmpSkip1::isSkipped(item)
        return true if NxBalls::itemIsRunning(item)
        return false if TmpSkip1::isSkipped(item)
        return false if item["mikuType"] == "TxCondition"
        true
    end

    # Listing::isInterruption(item)
    def self.isInterruption(item)
        item["interruption"]
    end

    # Regular main listing 
    # Listing::toString2(store, item)
    def self.toString2(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "      "
        hasChildren = PolyFunctions::hasChildren(item) ? " [children]".red : ""
        nx = (lambda {|item|
            return "" if item["nx0810"].nil?
            "[#{"%5.3f" % item["nx0810"]["position"]}] ".red
        }).call(item)
        line = "#{storePrefix} #{nx}#{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}#{hasChildren}"

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        line
    end

    # Listing::itemsForListing1()
    def self.itemsForListing1()
        items = [
            Anniversaries::listingItems(),
            Waves::listingItemsInterruption(),
            NxBackups::listingItems(),
            NxLines::listingItems(),
            NxDateds::listingItems(),
            NxFloats::listingItems(),
            NxTasks::activeItemsForListing(),
            Waves::nonInterruptionItemsForListing(),
            NxCores::listingItems()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
        i1, i2 = items.partition{|item| item["nx0810"] }
        i1.sort_by{|item| item["nx0810"]["position"] } + i2
    end

    # Listing::itemsForListing2()
    def self.itemsForListing2()
        wavecounter = 0
        Listing::itemsForListing1()
            .reduce([]){|selected_items, item|
                if selected_items.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected_items
                else
                    selected_items + [item]
                end
            }
            .map{|item|
                if item["mikuType"] == "Wave" then
                    if wavecounter >= 20 then
                        nil
                    else
                        wavecounter = wavecounter + 1
                        item
                    end
                else
                    item
                end
            }
            .compact
    end

    # -----------------------------------------
    # Ops

    # Listing::preliminaries(initialCodeTrace)
    def self.preliminaries(initialCodeTrace)
        if CommonUtils::catalystTraceCode() != initialCodeTrace then
            puts "Code change detected"
            exit
        end

        if Config::isPrimaryInstance() then
            NxBackups::processNotificationChannel()
        end

        if Config::isPrimaryInstance() and ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 86400) then
            Operations::periodicPrimaryInstanceMaintenance()
        end

        Operations::pickUpBufferIn()
    end

    # Listing::main()
    def self.main()
        initialCodeTrace = CommonUtils::catalystTraceCode()

        Thread.new {
            loop {
                (lambda {
                    NxBalls::all()
                        .select{|nxball| nxball["type"] == "running" }
                        .each{|nxball|
                            item = Items::itemOrNull(nxball["itemuuid"])
                            next if item.nil?
                            if item["mikuType"] == "Wave" then
                                if NxBalls::ballRunningTime(nxball) > 1800 then
                                    CommonUtils::onScreenNotification("Catalyst", "Wave is over running")
                                    sleep 2
                                end
                                next
                            end
                            if NxBalls::ballRunningTime(nxball) > 3600 then
                                CommonUtils::onScreenNotification("Catalyst", "#{item["mikuType"]} is over running")
                            end
                        }
                }).call()
                sleep 120
            }
        }

        Thread.new {
            sleep 60
            loop {
                Dispatch::pickup()
                sleep 60
            }
        }

        loop {
            Listing::preliminaries(initialCodeTrace)
            store = ItemStore.new()
            printer = lambda{|line| puts line }
            printer.call("")
            Operations::top_notifications().each{|notification|
                puts "notification: #{notification}"
            }
            (NxBalls::runningItems() + Listing::itemsForListing2())
                .reduce([]){|selected_items, item|
                    if selected_items.map{|i| i["uuid"] }.include?(item["uuid"]) then
                        selected_items
                    else
                        selected_items + [item]
                    end
                }
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    line = Listing::toString2(store, item)
                    printer.call(line)
                }
            input = LucilleCore::askQuestionAnswerAsString("> ")
            if input == "exit" then
                return
            end
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
