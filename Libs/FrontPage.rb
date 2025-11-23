class FrontPage

    # -----------------------------------------
    # Data

    # FrontPage::canBeDefault(item)
    def self.canBeDefault(item)
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
        listingPosition = " (#{ListingPosition::decideRatioListingOrNull(item["bx42"], item["nx41"], 0)})".yellow
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayload::suffixString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{listingPosition}"
        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end
        if NxBalls::itemIsActive(item) then
            line = line.yellow
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

    # FrontPage::isVisible(item)
    def self.isVisible(item)
        item["do-not-show-until-51"].nil? or item["do-not-show-until-51"] < Time.new.utc.iso8601 
    end

    # FrontPage::itemsForListing()
    def self.itemsForListing()
        items = Items::mikuType("NxPolymorph")
            .select{|item| item["bx42"]["btype"] != "task" }

        tasks = (lambda {
            uuids = XCache::getOrNull("20672dab-79cb-44e8-80d0-418cadd8b63c:#{CommonUtils::today()}")
            if uuids then
                tasks = JSON.parse(uuids)
                        .map{|uuid| Items::itemOrNull(uuid) }
                        .compact
                        .select{|item| item["mikuType"] == "NxPolymorph" }
                        .select{|item| item["bx42"]["btype"] == "task" }
                XCache::set("20672dab-79cb-44e8-80d0-418cadd8b63c:#{CommonUtils::today()}", JSON.generate(tasks.map{|item| item["uuid"]}))
                return tasks
            end
            tasks = Items::mikuType("NxPolymorph")
                        .select{|item| item["bx42"]["btype"] == "task" }
                        .sort_by{|item| item["nx41"]["position"] }
            tasks = tasks.take(10) + tasks.reverse.take(10)
            XCache::set("20672dab-79cb-44e8-80d0-418cadd8b63c:#{CommonUtils::today()}", JSON.generate(tasks.map{|item| item["uuid"]}))
            tasks
        }).call()

        (items + tasks)
            .select{|item| FrontPage::isVisible(item) }
            .map{|item|
                position, item = ListingPosition::decideItemListingPositionOrNull(item)
                {
                    "item" => item,
                    "position" => position
                }
            }
            .select{|packet| packet["position"] }
            .sort_by{|packet| packet["position"] }
            .map{|packet| packet["item"] }
    end

    # FrontPage::extraLines(item)
    def self.extraLines(item) # Array[String]
        if item["uxpayload-b4e4"] then
            if item["uxpayload-b4e4"]["type"] == "text" then
                return item["uxpayload-b4e4"]["text"].lines(chomp: true)
            end
        end
        []
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
                displayeduuids << item["uuid"]
                store.register(item, FrontPage::canBeDefault(item))
                line = FrontPage::toString2(store, item)
                puts line
                sheight = sheight - (line.size/swidth + 1)
                break if sheight <= 3
                FrontPage::extraLines(item)
                    .map{|line| line }
                    .each{|line|
                        puts line
                        sheight = sheight - (line.size/swidth + 1)
                        break if sheight <= 3
                    }
            }

        activePackets = NxBalls::activePackets()
        activePackets
            .sort_by{|packet| packet["startunixtime"] }
            .reverse
            .map{|packet| packet["item"] }
            .each{|item|
                next if displayeduuids.include?(item["uuid"])
                store.register(item, FrontPage::canBeDefault(item))
                line = FrontPage::toString2(store, item)
                puts line.green
                sheight = sheight - (line.size/swidth + 1)
                FrontPage::extraLines(item)
                    .map{|line| line }
                    .each{|line|
                        puts line
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

        Thread.new {
            loop {
                (lambda {
                    NxBalls::all()
                        .select{|nxball| nxball["type"] == "running" }
                        .each{|nxball|
                            item = Items::itemOrNull(nxball["itemuuid"])
                            next if item.nil?
                            if message = Operations::runningItemOverruningMessage(item) then
                                CommonUtils::onScreenNotification("Catalyst", message)
                            end
                        }
                }).call()
                sleep 120
            }
        }

        loop {
            FrontPage::preliminaries(initialCodeTrace)
            FrontPage::displayListing(initialCodeTrace)
        }
    end
end
