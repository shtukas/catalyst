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

    # FrontPage::toString2(store, item)
    def self.toString2(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : ""

        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{NxEngines::suffix(item)}#{UxPayloads::suffixString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{Donations::suffix(item)}#{DoNotShowUntil::suffix(item)}"

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

    # FrontPage::printItem(store, item, cursor, screen_width, depth)
    def self.printItem(store, item, cursor, screen_width, depth)
        return 0 if item.nil?

        store.register(item, FrontPage::canBeDefault(item))

        height = 0

        storePrefix = store ? "(#{store.prefixString()})" : ""

        cursor_string = "[#{Time.at(cursor).to_s[11, 5]}]"

        displacement = "    " * depth

        line = "#{storePrefix} #{cursor_string} #{displacement}#{PolyFunctions::toString(item)}#{NxEngines::suffix(item)}#{UxPayloads::suffixString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{Donations::suffix(item)}#{DoNotShowUntil::suffix(item)}"

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

        puts line

        height = height + (line.size/screen_width + 1)

        SubTasks::getSubtasks(item).each{|child|
            h2 = FrontPage::printItem(store, child, cursor, screen_width, depth+1)
            height += h2
        }

        height
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

    # FrontPage::itemsForListingOrdered()
    def self.itemsForListingOrdered()
        # not needed at the moment
    end

    # FrontPage::head()
    def self.head()
        [
            Anniversaries::listingItems(),
            Desktop::listingItems(),
            NxNotifications::listingItems(),
            Waves::listingItemsInterruption(),
            NxCounters::listingItems(),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item) }
            .select{|item| FrontPage::isAccessible(item) }
    end

    # FrontPage::today()
    def self.today()
        [
            NxOndates::listingItemsTodayAbsolute(),
            NxBackups::listingItems(),
            NxEngineDelegate::listingItems(),
            NxEngines::listingItems(),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item) }
            .select{|item| FrontPage::isAccessible(item) }
    end

    # FrontPage::tail()
    def self.tail()
        [
            NxOndates::listingItemsTail(),
            Waves::listingItemsNonInterruption(),
            BufferIn::listingItems(),
            NxTasks::listingItems(),
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item) }
            .select{|item| FrontPage::isAccessible(item) }
    end

    # FrontPage::displayListing(initialCodeTrace)
    def self.displayListing(initialCodeTrace)

        BufferIn::import()

        Broadcasts::processIncoming()
        NxNotifications::pickup()

        sheight = CommonUtils::screenHeight() - 5
        swidth = CommonUtils::screenWidth()

        if Config::isPrimaryInstance() then
            if (Time.new.to_i - XCache::getOrDefaultValue("e1450d85-3f2b-4c3c-9c57-5e034361e8d6", "0").to_i) > 86400 then
                Operations::globalMaintenance()
                XCache::set("e1450d85-3f2b-4c3c-9c57-5e034361e8d6", Time.new.to_i)
            end
        end

        system('clear')

        puts ""

        t1 = Time.new.to_f

        store = ItemStore.new()

        items = CommonUtils::removeDuplicateObjectsOnAttribute(NxPriorities::listingItems() + NxBalls::activeItems() + Dispatch::dispatch(FrontPage::head(), [], FrontPage::today(), FrontPage::tail()), "uuid")

        if Config::isPrimaryInstance() then
            report = `#{Config::pathToGalaxy()}/DataBank/Palmer/binary/palmer print-dispatch-missing-report`.strip
            if report != "" then
                puts "palmer: ".green + report.red
            end
        end

        cursor = Time.new.to_i

        items.each{|item|
            o = FrontPage::printItem(store, item, cursor, swidth, 0)
            cursor = cursor + Dispatch::item_to_timespan(item)
            sheight = sheight - o
            break if sheight <= 0
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
