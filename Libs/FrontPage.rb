class FrontPage

    # -----------------------------------------
    # Data

    # FrontPage::canBeDefault(item)
    def self.canBeDefault(item)
        return false if TmpSkip1::isSkipped(item)
        return true  if NxBalls::itemIsRunning(item)
        true
    end

    # FrontPage::isInterruption(item)
    def self.isInterruption(item)
        item["interruption"]
    end

    # FrontPage::toString2(store, item, is_main_listing = false)
    def self.toString2(store, item, is_main_listing = false)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : ""

        if is_main_listing then
            cursor = XCache::getOrNull("dispatch-start-unixtime:96282efed924:#{CommonUtils::today()}:#{item["uuid"]}")
            if cursor then
                cursor = cursor.to_i
                planning = "[#{Time.at(cursor).to_s[11, 5]}] ".red
            else
                planning = "        "
            end
        else
            planning = ""
        end

        line = "#{planning}#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayloads::suffixString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{ListingParenting::suffix(item)}#{Donations::suffix(item)}#{DoNotShowUntil::suffix(item)}"
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

    # FrontPage::itemsForListing()
    def self.itemsForListing()
        items = [
            NxBackups::listingItems(),
            NxOndates::listingItems(),
            Waves::listingItems(),
            BufferIn::listingItems(),
            NxActives::listingItems(),
            NxEngine::listingItems(),
            Nx42s::listingItems(),
            NxCounters::listingItems()
        ]
            .flatten

        items = items
            .select{|item| DoNotShowUntil::isVisible(item) }
            .select{|item| FrontPage::isAccessible(item) }
            .map{|item|
                {
                    "item" => item,
                    "position" => ListingPosition::listingPositionOrNull(item)
                }
            }
            .select{|packet| packet["position"]}
            .sort_by{|packet| packet["position"] }
            .map{|packet| packet["item"]}

        items = CommonUtils::removeDuplicateObjectsOnAttribute(items, "uuid")

        items
    end

    # FrontPage::displayListing(initialCodeTrace)
    def self.displayListing(initialCodeTrace)
        store = ItemStore.new()
        puts ""

        sheight = CommonUtils::screenHeight()
        swidth = CommonUtils::screenWidth()

        if Config::isPrimaryInstance() then
            if (Time.new.to_i - XCache::getOrDefaultValue("e1450d85-3f2b-4c3c-9c57-5e034361e8d6", "0").to_i) > 86400 then
                Operations::globalMaintenance()
                XCache::set("e1450d85-3f2b-4c3c-9c57-5e034361e8d6", Time.new.to_i)
            end
        end

        t1 = Time.new.to_f

        # ----------------------------------------------------------------------
        # Main listing

        Dispatch::itemsForListing(CommonUtils::removeDuplicateObjectsOnAttribute(NxBalls::activeItems() + FrontPage::itemsForListing(), "uuid"))
            .each{|item|
                stored_day = XCache::getOrNull("dispatch-day:c26001e4:#{CommonUtils::today()}:#{item["uuid"]}")
                if stored_day and stored_day != CommonUtils::today() then
                    next
                end

                stored_hour = XCache::getOrNull("dispatch-hour:3b96884a:#{CommonUtils::today()}:#{item["uuid"]}")
                if stored_hour and stored_hour.to_i >= 22 then
                    next
                end

                store.register(item, FrontPage::canBeDefault(item))
                line = FrontPage::toString2(store, item, true)
                puts line
                sheight = sheight - (line.size/swidth + 1)
                break if sheight <= 3
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
