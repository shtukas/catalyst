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
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}#{impt}#{hasChildren}#{Instances::suffix(item)}#{Nx2133::suffix(item)}"

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
            Waves::nonInterruptionItemsForListing(),
            NxTasks::importantItemsForListing(),
            NxCores::listingItems()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| Instances::canShowHere(item) }
        items = CommonUtils::removeDuplicateObjectsOnAttribute(items, "uuid")
        items
    end

    # Listing::getListingPositionOrNull(itemuuid)
    def self.getListingPositionOrNull(itemuuid)
        position = XCache::getOrNull("9951cd72-9cfd-4066-85d8-d512b829dc34:#{itemuuid}:#{CommonUtils::today()}")
        return nil if position.nil?
        position.to_f
    end

    # Listing::itemsForListing1_v2()
    def self.itemsForListing1_v2()
        items1 = [
            Anniversaries::listingItems(),
            Waves::listingItemsInterruption(),
            NxBackups::listingItems(),
            NxLines::listingItems()
        ]
            .flatten

        items2 = [
            NxDateds::listingItems(),
            NxFloats::listingItems(),
            Waves::nonInterruptionItemsForListing(),
            NxTasks::importantItemsForListing()
        ]
            .flatten

        items2 = items2.sort_by{|item|
            Nx2133::getNx(item)["position"]
        }

        items3 = [
            NxCores::listingItems()
        ]
            .flatten

        items = (items1 + items2 + items3)
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|item| Instances::canShowHere(item) }

        items = CommonUtils::removeDuplicateObjectsOnAttribute(items, "uuid")
        items
    end

    # Listing::itemsForListing2()
    def self.itemsForListing2()
        items = Listing::itemsForListing1_v2()
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

        if Instances::isPrimaryInstance() then
            NxBackups::processNotificationChannel()
        end

        if Instances::isPrimaryInstance() and ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 86400) then
            Operations::periodicPrimaryInstanceMaintenance()
        end

        Operations::dispatchPickUp()
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
        Operations::topNotifications().each{|notification|
            puts "notification: #{notification}"
        }

        sheight = CommonUtils::screenHeight()
        swidth = CommonUtils::screenWidth()

        t1 = Time.new.to_f
        Listing::itemsForListing2()
            .each{|item|
                store.register(item, Listing::canBeDefault(item))
                line = Listing::toString2(store, item)
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
