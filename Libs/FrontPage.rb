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
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayloads::suffixString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{ListingParenting::suffix(item)}#{Donations::suffix(item)}#{DoNotShowUntil::suffix(item)}"
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

    # FrontPage::toString3_main_listing(store, item)
    def self.toString3_main_listing(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : ""

        if Config::isPrimaryInstance() then
            nx2 = XCache::getOrNull("nx2:295e252e-9732-4c9d-9020-12374a2c334c:#{item["uuid"]}")
            if nx2 then
                nx2 = JSON.parse(nx2)
                duration_ = "[#{nx2["start-datetime"][11, 5]}, #{nx2["end-datetime"][11, 5]} (#{"%3d" % nx2["duration"]})] ".red
            else
                duration_ = ""
            end
        else
            duration_ = ""
        end

        time_ = item["start-time-cursor-21"] ? "[#{Time.at(item["start-time-cursor-21"]).to_s[11, 5]}] ".red : ""
        line = "#{duration_}#{time_}#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayloads::suffixString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{ListingParenting::suffix(item)}#{Donations::suffix(item)}#{DoNotShowUntil::suffix(item)}"
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
            if Config::instanceId().start_with?("Lucille26") then
                # We don't do Dx8Units on Lucille26
                return false
            end
        end
        true
    end

    # FrontPage::itemsAndBucketPositionsForListing()
    def self.itemsAndBucketPositionsForListing()
        items = [
            NxBackups::listingItems(),
            NxOndates::listingItems(),
            Blades::mikuType("NxToday"),
            Waves::listingItems(),
            BufferIn::listingItems(),
            Floats::listingItems(),
            NxEngines::listingItems(),
            Nx42s::listingItems(),
            NxCounters::listingItems()
        ]
            .flatten

        items = CommonUtils::removeDuplicateObjectsOnAttribute(items, "uuid")

        items
            .select{|item| DoNotShowUntil::isVisible(item) }
            .select{|item| FrontPage::isAccessible(item) }
            .select{|item|
                if NxBalls::itemIsActive(item) then
                    true
                else
                    if item["duration-38"] then
                        Bank::getValueAtDate(item["uuid"], CommonUtils::today()) < (item["duration-38"] * 60)
                    else
                        true
                    end
                end
            }
            .map{|item|
                data = ListingPosition::listingBucketAndPositionOrNull(item)
                item["bucket&position"] = data
                {
                    "item" => item,
                    "bucket&position" => data
                }
            }
            .select{|packet| packet["bucket&position"] }
            .sort_by{|packet| packet["bucket&position"][1] }
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

        # ----------------------------------------------------------------------
        # Data Works

        nx1s = FrontPage::itemsAndBucketPositionsForListing()
        #nx1: {
        #    "item"            : item,
        #    "bucket&position" : data
        #}

        if Config::isPrimaryInstance() then
            Planning::distribute(nx1s)
            planningstatus = Planning::planningStatus(nx1s)
            if planningstatus then
                puts "planning status: #{planningstatus}".green
            end
        end

        # ----------------------------------------------------------------------
        # Main listing

        displayeduuids = []

        nx1s
            .each{|nx1|
                item = nx1["item"]
                bucket, position = nx1["bucket&position"]
                Prefix::prefix(item).each{|itemx|
                    next if displayeduuids.include?(itemx["uuid"])
                    displayeduuids << itemx["uuid"]
                    store.register(itemx, FrontPage::canBeDefault(itemx))
                    line = FrontPage::toString3_main_listing(store, itemx)
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
