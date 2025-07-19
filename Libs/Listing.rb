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

    # Listing::toString2(store, item)
    def self.toString2(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : ""
        hasChildren = Index2::hasChildren(item["uuid"]) ? " [children]".red : ""
        impt = item["nx2290-important"] ? " [important]".red : ""
        position = " (#{item["x-listing-position"]})".yellow
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}#{impt}#{hasChildren}#{position}"

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
            NxLines::listingItems(),
            NxBackups::listingItems(),
            NxDateds::listingItems(),
            NxFloats::listingItems(),
            Waves::nonInterruptionItemsForListing(),
            NxTasks::importantItemsForListing(),
            NxCores::listingItems()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # -----------------------------------------
    # Ops

    # Listing::preliminaries(initialCodeTrace)
    def self.preliminaries(initialCodeTrace)
        if CommonUtils::catalystTraceCode() != initialCodeTrace then
            puts "Code change detected"
            exit
        end

        Operations::dispatchPickUp()
    end

    # Listing::displayListingItem(store, printer, item)
    def self.displayListingItem(store, printer, item)
        lines = []
        Index2::parentuuidToChildrenInOrder(item["uuid"])
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

        sheight = CommonUtils::screenHeight()
        swidth = CommonUtils::screenWidth()

        if XCacheExensions::trueNoMoreOftenThanNSeconds("e1450d85-3f2b-4c3c-9c57-5e034361e8d5", 40000) then
            puts "Running global maintenance (every half a day)"
            Operations::globalMaintenance()
            XCache::set("e1450d85-3f2b-4c3c-9c57-5e034361e8d5", Time.new.to_i)
        end

        if XCacheExensions::trueNoMoreOftenThanNSeconds("80f6dfde-ccca-4ee4-b0e4-9d93794fac5e", 3600) then
            puts "Running listing maintenance (every hour)"
            Index0::listingMaintenance()
            XCache::set("80f6dfde-ccca-4ee4-b0e4-9d93794fac5e", Time.new.to_i)
        end

        t1 = Time.new.to_f
        runningItems = NxBalls::runningItems()
        NxBalls::runningItems()
            .each{|item|
                store.register(item, Listing::canBeDefault(item))
                line = Listing::toString2(store, item)
                printer.call(line)
                sheight = sheight - (line.size/swidth + 1)
                break if sheight <= 4
            }

        Index0::itemsForListing(runningItems.map{|i| i["uuid"]})
            .each{|entry|
                store.register(entry["item"], Listing::canBeDefault(entry["item"]))
                line = entry["line"].gsub("STORE-PREFIX", "(#{store.prefixString()})")
                printer.call(line)
                sheight = sheight - (line.size/swidth + 1)
                break if sheight <= 4
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
                puts line.green
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
