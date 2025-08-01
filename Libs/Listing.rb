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
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}#{hasChildren}"

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
            NxProjects::listingItems(),
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

    # Listing::displayListingOnce()
    def self.displayListingOnce()
        store = ItemStore.new()
        printer = lambda{|line| puts line }
        printer.call("")

        sheight = CommonUtils::screenHeight()
        swidth = CommonUtils::screenWidth()

        # Automatic Scheduled Maintenance

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

        # Palmer reporting

        performance = `palmer report:performance`.strip
        i = performance.index('(')
        percentage = performance[i, 10].to_f
        if percentage < 100 then
            puts performance.red
        else
            if percentage < 120 then
                puts performance.yellow
            end
        end

        # Projects morning set up

        date = IO.read("#{Config::pathToCatalystDataRepository()}/last-configure-projects-today-date.txt").strip
        if date != CommonUtils::today() then
            item = NxLambdas::interactivelyIssueNewOrNull(
                "configure projects today",
                lambda {
                    Operations::interactivelyDecideDayPriorityItems()
                    File.open("#{Config::pathToCatalystDataRepository()}/last-configure-projects-today-date.txt", "w"){|f| f.puts(CommonUtils::today()) }
                }
            )
            store.register(item, true)
            printer.call(Listing::toString2(store, item))
        end

        t1 = Time.new.to_f

        # Main listing

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
                item = entry["item"]
                line = entry["listing_line"]
                store.register(item, Listing::canBeDefault(item))
                line = line.gsub("STORE-PREFIX", "(#{store.prefixString()})")
                line = line + " (#{entry["position"]})".yellow
                printer.call(line)
                sheight = sheight - (line.size/swidth + 1)
                break if sheight <= 4
            }

        t2 = Time.new.to_f
        renderingTime = t2-t1
        if renderingTime > 0.5 then
            puts "rendering time: #{renderingTime.round(3)} seconds".red
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
