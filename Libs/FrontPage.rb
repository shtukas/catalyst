class FrontPage

    # -----------------------------------------
    # Data

    # FrontPage::canBeDefault(item)
    def self.canBeDefault(item)
        return false if item["mikuType"] == "Float"
        return false if TmpSkip1::isSkipped(item)
        return true if NxBalls::itemIsRunning(item)
        return false if TmpSkip1::isSkipped(item)
        true
    end

    # FrontPage::isInterruption(item)
    def self.isInterruption(item)
        item["interruption"]
    end

    # FrontPage::toString2(store, item)
    def self.toString2(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : ""
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayloads::suffixString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{Donations::suffix(item)}#{DoNotShowUntil::suffix(item)}"
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

    # FrontPage::isAccessible(item)
    def self.isAccessible(item)
        if item["payload-37"] and item["payload-37"]["mikuType"] == "Dx8Unit" then
            if Config::instanceId() == "Lucille26-pascal-honore" then
                return false
            end
        end
        true
    end

    # FrontPage::itemsForListing()
    def self.itemsForListing()
        [
            NxBackups::listingItems(),
            NxOndates::listingItems(),
            Blades::mikuType("NxToday"),
            Waves::listingItems(),
            BufferIn::listingItems(),
            NxListings::listingItems(),
            Floats::listingItems(),
            NxEngines::listingItems(),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item) }
            .select{|item| FrontPage::isAccessible(item) }
            .map{|item| {
                "item" => item,
                "position" => ListingPosition::decideItemListingPositionOrNull(item)
            }}
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

        if Config::isPrimaryInstance() then
            if XCacheExensions::trueNoMoreOftenThanNSeconds("e1450d85-3f2b-4c3c-9c57-5e034361e8d5", 3600*12) then
                Operations::globalMaintenanceSync()
                XCache::set("e1450d85-3f2b-4c3c-9c57-5e034361e8d5", Time.new.to_i)
            end
        end

        t1 = Time.new.to_f

        # Main listing

        displayeduuids = []

        FrontPage::itemsForListing()
            .each{|item_|
                Prefix::prefix(item_).each{|item|
                    next if displayeduuids.include?(item["uuid"])
                    displayeduuids << item["uuid"]
                    store.register(item, FrontPage::canBeDefault(item))
                    line = FrontPage::toString2(store, item)
                    puts line
                    sheight = sheight - (line.size/swidth + 1)
                    break if sheight <= 3
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

        Thread.new {
            loop {
                sleep 3600
                Operations::globalMaintenanceASync()
            }
        }

        loop {
            FrontPage::preliminaries(initialCodeTrace)
            FrontPage::displayListing(initialCodeTrace)
        }
    end
end
