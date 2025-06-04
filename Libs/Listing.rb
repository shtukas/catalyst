class TheZone

    # TheZone::pulse()
    def self.pulse()
        (Time.new.to_i.to_f/3000).to_i.to_s
    end

    # TheZone::recomputeFromZero()
    def self.recomputeFromZero()
        items = Listing::itemsForListing1()
        XCache::set("ddbb56f5-82e4-4ffa-a6e4-17582cbd9544:#{TheZone::pulse()}", JSON.generate(items))
    end

    # TheZone::items()
    def self.items()
        JSON.parse(XCache::getOrDefaultValue("ddbb56f5-82e4-4ffa-a6e4-17582cbd9544:#{TheZone::pulse()}", "[]"))
    end

    # TheZone::removeItemFromTheZone(item)
    def self.removeItemFromTheZone(item)
        items = TheZone::items()
        items = items.reject{|i| i["uuid"] == item["uuid"] }
        XCache::set("ddbb56f5-82e4-4ffa-a6e4-17582cbd9544:#{TheZone::pulse()}", JSON.generate(items))
    end

    # TheZone::repositionItemInTheZone(item)
    def self.repositionItemInTheZone(item)
        items = TheZone::items()
        items = items.map{|i|
            if i["uuid"] == item["uuid"] then
                item
            else
                i
            end
        }
        present = items.any?{|i| i["uuid"] == item["uuid"] }
        if !present then
            items = items.take(10) + [item] + items.drop(10)
        end
        XCache::set("ddbb56f5-82e4-4ffa-a6e4-17582cbd9544:#{TheZone::pulse()}", JSON.generate(items))

        string = TheZone::toString3(item)
        XCache::set("ca006f3f-5cd4-4d14-bf21-82d828702e8a:#{item["uuid"]}", string)
    end

    # TheZone::toString3(item)
    def self.toString3(item)
        return nil if item.nil?
        hasChildren = PolyFunctions::hasChildren(item) ? " [children]".red : ""
        line = "STORE-PREFIX #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{DoNotShowUntil::suffix2(item)}#{hasChildren}"
        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end
        if NxBalls::itemIsActive(item) then
            line = line.green
        end
        line
    end

    # TheZone::itemToString(store, item)
    def self.itemToString(store, item)
        string = XCache::getOrNull("ca006f3f-5cd4-4d14-bf21-82d828702e8a:#{item["uuid"]}")
        if string.nil? then
            string = TheZone::toString3(item)
            XCache::set("ca006f3f-5cd4-4d14-bf21-82d828702e8a:#{item["uuid"]}", string)
        end
        storePrefix = store ? "(#{store.prefixString()})" : "      "
        string.gsub("STORE-PREFIX", storePrefix)
    end
end

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
        hasChildren = PolyFunctions::hasChildren(item) ? " [children]".red : ""
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
        [
            Items::mikuType("NxStackPriority"),
            Anniversaries::listingItems(),
            Waves::listingItemsInterruption(),
            NxBackups::listingItems(),
            NxDateds::listingItems(),
            NxFloats::listingItems(),
            Waves::nonInterruptionItemsForListing(),
            NxTasks::activeItemsForListing(),
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

        if Config::isPrimaryInstance() then
            NxBackups::processNotificationChannel()
        end

        if Config::isPrimaryInstance() and ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 86400) then
            Operations::periodicPrimaryInstanceMaintenance()
        end

        Operations::pickUpBufferIn()
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
            sleep 5
            loop {
                TheZone::recomputeFromZero()
                sleep 600
            }
        }

        loop {
            Listing::preliminaries(initialCodeTrace)
            store = ItemStore.new()
            printer = lambda{|line| puts line }
            printer.call("")
            Operations::top_notifications().each{|notification|
                puts "notification: #{notification}"
            }
            TheZone::items()
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    line = TheZone::itemToString(store, item)
                    printer.call(line)
                }
            input = LucilleCore::askQuestionAnswerAsString("> ")
            if input == "exit" then
                return
            end
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
