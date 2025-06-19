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
        storePrefix = store ? "(#{store.prefixString()})" : ""
        hasChildren = PolyFunctions::hasChildren(item) ? " [children]".red : ""
        impt = item["nx2290-important"] ? " [important]".red : ""
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}#{impt}#{hasChildren}"

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
        blocks = [
            {
                "items" => [
                    Anniversaries::listingItems(),
                    Waves::listingItemsInterruption(),
                    NxBackups::listingItems(),
                    NxLines::listingItems(),
                    NxDateds::listingItems(),
                    NxFloats::listingItems(),
                ],
                "metric" => -1 # we want that one first
            },
            {
                "items" => [
                    NxTasks::importantItemsForListing(),
                ],
                "metric" => Bank1::recoveredAverageHoursPerDay("block:important-items:40c3f5929ca6")
            },
            {
                "items" => [
                    Waves::nonInterruptionItemsForListing(),
                ],
                "metric" => Bank1::recoveredAverageHoursPerDay("block:waves:80fcd1ca16d3")
            },
            {
                "items" => [
                    NxCores::listingItems(),
                ],
                "metric" => 24 # which is the maximum value
            },
        ]

        items = blocks
            .sort_by{|block| block["metric"] }
            .map{|block| block["items"] }
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
        items = CommonUtils::removeDuplicateObjectsOnAttribute(items, "uuid")
        items
    end

    # Listing::itemsForListing2()
    def self.itemsForListing2()
        items = Listing::itemsForListing1()
        items = items.take(10) + NxBalls::runningItems() + items.drop(10)
        items = CommonUtils::removeDuplicateObjectsOnAttribute(items, "uuid")
        items
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

    # Listing::displayListingItem(store, printer, item)
    def self.displayListingItem(store, printer, item)
        lines = []
        PolyFunctions::childrenInOrder(item)
        .reduce([]){|selected, child|
            if selected.size >= 3 then
                selected
            else
                if NxBalls::itemIsActive(child) or ((Bank1::getValueAtDate(child["uuid"], CommonUtils::today()) < 1) and DoNotShowUntil::isVisible(child["uuid"])) then
                    selected + [child]
                else
                    selected
                end
            end
        }
        .each {|child|
            lines = lines + Listing::displayListingItem(store, printer, child)
        }
        store.register(item, Listing::canBeDefault(item))
        line = Listing::toString2(store, item)
        printer.call(line)
        lines << line
        lines
    end

    # Listing::displayListingOnce()
    def self.displayListingOnce()
        store = ItemStore.new()
        printer = lambda{|line| puts line }
        printer.call("")
        Operations::top_notifications().each{|notification|
            puts "notification: #{notification}"
        }

        sheight = CommonUtils::screenHeight()
        swidth = CommonUtils::screenWidth()

        t1 = Time.new.to_f
        Listing::itemsForListing2()
            .each{|item|
                lines = Listing::displayListingItem(store, printer, item)
                sheight = sheight - lines.map{|line| (line.size/swidth + 1) }.sum
                break if sheight <= 3
            }

        t2 = Time.new.to_f
        renderingTime = t2-t1
        if renderingTime > 0.5 then
            puts "rendering time: #{renderingTime.round(3)} seconds".red
        end

        begin
            line = `palmer report:performance`.strip.lines.drop(2).first
            if line.include?("Missing") then
                puts line.red
            else
                puts line.yellow
            end
            
        rescue
            puts "could not retrieve palmer performance report".red
        end

        input = LucilleCore::askQuestionAnswerAsString("> ")
        if input == "exit" then
            return
        end
        CommandsAndInterpreters::interpreter(input, store)
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

        loop {
            Listing::preliminaries(initialCodeTrace)
            Listing::displayListingOnce()
        }
    end
end
