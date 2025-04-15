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
        storePrefix = store ? "(#{store.prefixString()})" : "      "
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}"

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        line
    end

    # toString for Operations::program3
    # Listing::toString3(store, item)
    def self.toString3(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "      "
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}"

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
        i1 = Items::mikuType("NxStackPriority")
        i2 = Anniversaries::listingItems()
        i3 = Waves::listingItemsInterruption()
        i4 = NxBackups::listingItems()
        i5 = NxDateds::listingItems()
        i6 = NxFloats::listingItems()
        i8 = Waves::listingItemsNonInterruption()
        i9 = NxTasks::activeItemsForListing()
        i10 = NxTasks::itemsForListing()

        (i1 + i2 + i3 + i4 + i5 + i6 + i8 + i9 + i10)
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # Listing::itemsForListing2()
    def self.itemsForListing2()
        items = Listing::itemsForListing1()
        items = Prefix::addPrefix(items)
        items = items.take(10) + NxBalls::activeItems() + items.drop(10)
        items = items
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
        items = items.take(CommonUtils::screenHeight()-5)
        items
    end

    # Listing::itemsForListing3()
    def self.itemsForListing3()
        JSON.parse(XCache::getOrDefaultValue("a703683f-764f-47fb-ba9c-bf1f154490e2", "[]"))
    end

    # Listing::removeItemFromCache(uuid)
    def self.removeItemFromCache(uuid)
        items = JSON.parse(XCache::getOrDefaultValue("a703683f-764f-47fb-ba9c-bf1f154490e2", "[]"))
        items = items.reject{|item| item["uuid"] == uuid }
        XCache::set("a703683f-764f-47fb-ba9c-bf1f154490e2", JSON.generate(items))
    end

    # Listing::refreshItemInCache(uuid)
    def self.refreshItemInCache(uuid)
        items = JSON.parse(XCache::getOrDefaultValue("a703683f-764f-47fb-ba9c-bf1f154490e2", "[]"))
        items = items.map{|i|
            if i["uuid"] == uuid then
                Items::itemOrNull(uuid)
            else
                i
            end
        }
        .compact
        XCache::set("a703683f-764f-47fb-ba9c-bf1f154490e2", JSON.generate(items))
    end

    # -----------------------------------------
    # Ops

    # Listing::preliminaries(initialCodeTrace)
    def self.preliminaries(initialCodeTrace)
        if CommonUtils::catalystTraceCode() != initialCodeTrace then
            puts "Code change detected"
            exit
        end

        if Config::isPrimaryInstance() then
            Items::processJournal()
            Bank1::processJournal()
            NxBackups::processNotificationChannel()
        end

        if Config::isPrimaryInstance() and ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 86400) then
            Operations::periodicPrimaryInstanceMaintenance()
        end

        Operations::pickUpBufferIn()
    end

    # Listing::display_listing(printer)
    def self.display_listing(printer)
        t1 = Time.new.to_f

        NxDateds::processPastItems()
        items = Listing::itemsForListing3()

        store = ItemStore.new()
        printer.call("")
        items
            .each{|item|
                store.register(item, Listing::canBeDefault(item))
                line = Listing::toString2(store, item)
                printer.call(line)
            }

        if items.empty? then
            puts "moon 🚀 : #{IO.read("#{Config::pathToCatalystDataRepository()}/moon.txt")}"
        end

        renderingTime = Time.new.to_f - t1
        if renderingTime > 1 then
            printer.call("(rendered in #{(Time.new.to_f - t1).round(3)} s)".red)
        end

        store
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

        Thread.new {
            loop {
                sleep 60
                items = Listing::itemsForListing2()
                XCache::set("a703683f-764f-47fb-ba9c-bf1f154490e2", JSON.generate(items))
            }
        }

        loop {
            Listing::preliminaries(initialCodeTrace)
            store = Listing::display_listing(lambda{|line| puts line })
            input = LucilleCore::askQuestionAnswerAsString("> ")
            if input == "exit" then
                return
            end
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
