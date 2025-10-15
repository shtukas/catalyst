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
        lp = " (#{TxBehaviour::behaviourToListingPosition(item["behaviours"].first)})".yellow
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
        Items::mikuType("NxPolymorph")
            .map{|item| NxPolymorphs::identityOrSimilarWithUpdatedBehaviours(item) }
            .select{|item| TxBehaviour::isVisibleOnFrontPage(item["behaviours"].first) }
            .sort_by{|item| TxBehaviour::behaviourToListingPosition(item["behaviours"].first) }
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
                break if sheight <= 4
            }

        items = FrontPage::itemsForListing()
        items
            .each{|item|
                next if displayedItems.include?(item["uuid"])
                store.register(item, FrontPage::canBeDefault(item))
                line = FrontPage::toString2(store, item)
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
