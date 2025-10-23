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
        lp = " (#{TxBehaviour::behaviourToListingPositionOrNull(item["behaviours"].first)})".yellow
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{lp}"
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
        Operations::dispatchPickUp()
    end

    # FrontPage::itemsForListing()
    def self.itemsForListing()
        tasks = (lambda {
            uuids = XCache::getOrNull("20672dab-79cb-44e8-80d0-418cadd8b62b:#{CommonUtils::today()}")
            if uuids then
                tasks = JSON.parse(uuids)
                        .map{|uuid| Items::itemOrNull(uuid) }
                        .compact
                        .select{|item| item["behaviours"][0]["btype"] == "task" }
                XCache::set("20672dab-79cb-44e8-80d0-418cadd8b62b:#{CommonUtils::today()}", JSON.generate(tasks.map{|item| item["uuid"]}))
                return tasks
            end
            tasks = Items::mikuType("NxPolymorph")
                        .select{|item| item["behaviours"][0]["btype"] == "task" }
                        .select{|item| TxBehaviour::behaviourToListingPositionOrNull(item["behaviours"].first) }
                        .sort_by{|item| TxBehaviour::behaviourToListingPositionOrNull(item["behaviours"].first) }
                        .take(10)
            XCache::set("20672dab-79cb-44e8-80d0-418cadd8b62b:#{CommonUtils::today()}", JSON.generate(tasks.map{|item| item["uuid"]}))
            tasks
        }).call()

        items = Items::mikuType("NxPolymorph")
            .select{|item| item["behaviours"][0]["btype"] != "task" }
            .map{|item| NxPolymorphs::identityOrSimilarWithUpdatedBehaviours(item) }
            .select{|item| TxBehaviour::behaviourToListingPositionOrNull(item["behaviours"].first) }

        (items + tasks).sort_by{|item| TxBehaviour::behaviourToListingPositionOrNull(item["behaviours"].first) }
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

    # FrontPage::displayListing()
    def self.displayListing()
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

        Operations::monitor()

        t1 = Time.new.to_f

        # Main listing

        displayedItems = []

        activePackets = NxBalls::activePackets()
        activePackets
            .sort_by{|packet| packet["startunixtime"] }
            .reverse
            .map{|packet| packet["item"] }
            .each{|item|
                displayedItems << item["uuid"]
                store.register(item, FrontPage::canBeDefault(item))
                line = FrontPage::toString2(store, item)
                printer.call(line.green)
                sheight = sheight - (line.size/swidth + 1)
                FrontPage::extraLines(item)
                    .map{|line| "         #{line}" }
                    .each{|line|
                        printer.call(line)
                        sheight = sheight - (line.size/swidth + 1)
                    }
            }

        taskscount = 0

        FrontPage::itemsForListing()
            .each{|item|
                next if displayedItems.include?(item["uuid"])
                store.register(item, FrontPage::canBeDefault(item))
                line = FrontPage::toString2(store, item)
                printer.call(line)
                sheight = sheight - (line.size/swidth + 1)
                break if sheight <= 3
                FrontPage::extraLines(item)
                    .map{|line| "         #{line}" }
                    .each{|line|
                        printer.call(line)
                        sheight = sheight - (line.size/swidth + 1)
                        break if sheight <= 3
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
                            if NxBalls::ballRunningTime(nxball) > 3600 then
                                CommonUtils::onScreenNotification("Catalyst", "item is over running")
                            end
                        }
                }).call()
                sleep 120
            }
        }

        Thread.new {
            loop {
                (lambda {
                    return if NxBalls::all().any?{|nxball| nxball["type"] == "running" }
                    items = FrontPage::itemsForListing().select{|item| item["behaviours"].first["btype"] != "task" }
                    return if items.empty?
                    endunixtime = items
                            .select{|item| item["behaviours"].first["btype"] == "DayCalendarItem" }
                            .map{|item| item["behaviours"].first }
                            .map{|behaviour| behaviour["start-unixtime"] + behaviour["durationInMinutes"]*60 }
                            .sort
                            .first
                    return if endunixtime.nil?
                    if Time.new.to_i > (endunixtime - 60) then
                        CommonUtils::onScreenNotification("Catalyst", "check for calendar overrun")
                    end
                }).call()
                sleep 120
            }
        }

        Thread.new {
            loop {
                sleep 300
                LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/items-destroyed")
                    .select{|filepath| filepath[-4, 4] == ".txt" }
                    .each{|filepath|
                        uuid = IO.read(filepath).strip
                        status = Datablocks::removeUUID(uuid)
                        if status and File.exist?(filepath) then
                            FileUtils.rm(filepath)
                        end
                    }
            }
        }

        loop {
            FrontPage::preliminaries(initialCodeTrace)
            FrontPage::displayListing()
        }
    end
end
