class FrontPage

    # -----------------------------------------
    # Data

    # FrontPage::canBeDefault(item)
    def self.canBeDefault(item)
        return false if TmpSkip1::isSkipped(item)
        return true if NxBalls::itemIsRunning(item)
        return false if TmpSkip1::isSkipped(item)
        return false if item["mikuType"] == "NxHappening"
        true
    end

    # FrontPage::additionalLines(item)
    def self.additionalLines(item)
        sublines = NxSublines::itemsForParentInOrder(item["uuid"])
        sublines.map{|s| NxSublines::toString(s) }
    end

    # FrontPage::additionalLinesShift(item)
    def self.additionalLinesShift(item)
        9
    end

    # FrontPage::isInterruption(item)
    def self.isInterruption(item)
        item["interruption"]
    end

    # FrontPage::toString2(store, item)
    def self.toString2(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : ""
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayloads::suffixString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil::suffix(item)}"
        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end
        if !DoNotShowUntil::isVisible(item) then
            line = line.yellow
        end
        if NxBalls::itemIsActive(item) then
            line = line.green
        end
        if NxBalls::itemIsRunning(item) then
            line = line.green
        end
        line
    end

    # -----------------------------------------
    # Ops

    # FrontPage::preliminaries(initialCodeTrace)
    def self.preliminaries(initialCodeTrace)
        if CommonUtils::catalystTraceCode() != initialCodeTrace then
            puts "Code change detected"
            exit
        end
    end

    # FrontPage::itemsForListing()
    def self.itemsForListing()
        [
            NxTasks::listingItems(),
            Items::mikuType("NxLine"),
            Waves::listingItems(),
            NxHappenings::listingItems(),
            NxOndates::listingItems()
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item) }
            .map{|item|
                {
                    "item" => item,
                    "position" => ListingPosition::decideItemListingPositionOrNull(item)
                }
            }
            .select{|packet| packet["position"] }
            .sort_by{|packet| packet["position"] }
            .map{|packet| packet["item"] }
    end

    # FrontPage::displayListing(initialCodeTrace)
    def self.displayListing(initialCodeTrace)
        store = ItemStore.new()
        puts ""

        sheight = CommonUtils::screenHeight()
        swidth = CommonUtils::screenWidth()

        # Automatic Scheduled Maintenance

        if XCacheExensions::trueNoMoreOftenThanNSeconds("e1450d85-3f2b-4c3c-9c57-5e034361e8d5", 40000) then
            puts "Running global maintenance (every half a day)"
            Operations::globalMaintenance()
            XCache::set("e1450d85-3f2b-4c3c-9c57-5e034361e8d5", Time.new.to_i)
        end

        t1 = Time.new.to_f

        # Main listing

        displayeduuids = []

        FrontPage::itemsForListing()
            .each{|item|
                next if displayeduuids.include?(item["uuid"])
                displayeduuids << item["uuid"]
                store.register(item, FrontPage::canBeDefault(item))
                line = FrontPage::toString2(store, item)
                puts line
                sheight = sheight - (line.size/swidth + 1)
                FrontPage::additionalLines(item).each{|line|
                    puts " " * FrontPage::additionalLinesShift(item) + line
                    sheight = sheight - (line.size/swidth + 1)
                }
                break if sheight <= 3
            }

        activePackets = NxBalls::activePackets()
        activePackets
            .sort_by{|packet| packet["startunixtime"] }
            .reverse
            .map{|packet| packet["item"] }
            .each{|item|
                next if displayeduuids.include?(item["uuid"])
                displayeduuids << item["uuid"]
                store.register(item, FrontPage::canBeDefault(item))
                line = FrontPage::toString2(store, item)
                puts line.green
                sheight = sheight - (line.size/swidth + 1)
                FrontPage::additionalLines(item).each{|line|
                    puts " " * FrontPage::additionalLinesShift(item) + line
                    sheight = sheight - (line.size/swidth + 1)
                }
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

    # FrontPage::main()
    def self.main()
        initialCodeTrace = CommonUtils::catalystTraceCode()
        loop {
            FrontPage::preliminaries(initialCodeTrace)
            FrontPage::displayListing(initialCodeTrace)
        }
    end
end
