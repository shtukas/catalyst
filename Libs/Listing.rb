
class Timings
    def initialize()
    end

    def start_contest()
        @contest = []
    end

    def contest_entry(description, l)
        t1 = Time.new.to_f
        l.call()
        t2 = Time.new.to_f
        @contest << {
            "description" => description,
            "time"        => t2 - t1
        }
    end

    def end_contest()
        @contest
            .sort_by{|entry| entry["time"] }
            .reverse
            .each{|entry| puts "#{"%6.2f" % entry["time"]}: #{entry["description"]}" }
    end

    def start_unit(description)
        @description = description
        @t = Time.new.to_f
    end

    def end_unit()
        puts "#{"%6.2f" % (Time.new.to_f - @t)}: #{@description}"
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
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{PolyFunctions::parentingSuffix(item)}#{DoNotShowUntil::suffix(item)}"

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
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{PolyFunctions::parentingSuffix(item)}#{DoNotShowUntil::suffix(item)}"

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        line
    end

    # Listing::itemsForListing()
    def self.itemsForListing()
        [
            Items::mikuType("NxStackPriority"),
            Anniversaries::listingItems(),
            Waves::listingItemsInterruption(),
            NxBackups::listingItems(),
            NxDateds::listingItems(),
            NxFloats::listingItems(),
            NxMonitors::listingItems(),
            NxTasks::itemsForListing(),
            Waves::listingItemsNonInterruption(),
            NxCores::inRatioOrder(),
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
            Items::processJournal()
            Bank1::processJournal()
            NxBackups::processNotificationChannel()
        end

        if Config::isPrimaryInstance() and ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 86400) then
            Operations::periodicPrimaryInstanceMaintenance()
        end
    end

    # Listing::listingOnce(printer)
    def self.listingOnce(printer)
        t1 = Time.new.to_f

        Timings::start()

        Timings::lap("17:20")

        items = Listing::itemsForListing()

        Timings::lap("17:40")

        items = Prefix::addPrefix(items)

        Timings::lap("17:47")

        items = items.take(10) + NxBalls::activeItems() + items.drop(10)

        Timings::lap("19:30")

        items = items
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }

        Timings::lap("22:08")

        store = ItemStore.new()

        printer.call("")

        items = items.take(CommonUtils::screenHeight()-5)

        Timings::lap("22:09")

        items
            .each{|item|
                store.register(item, Listing::canBeDefault(item))
                line = Listing::toString2(store, item)
                printer.call(line)
            }

        Timings::lap("22:10")

        renderingTime = Time.new.to_f - t1
        if renderingTime > 1 then
            printer.call("(rendered in #{(Time.new.to_f - t1).round(3)} s)".red)
        end

        store
    end

    # Listing::runContinuousListing(initialCodeTrace)
    def self.runContinuousListing(initialCodeTrace)
        loop {
            Listing::preliminaries(initialCodeTrace)
            store = Listing::listingOnce(lambda{|line| puts line })
            input = LucilleCore::askQuestionAnswerAsString("> ")
            if input == "exit" then
                return
            end
            CommandsAndInterpreters::interpreter(input, store)
        }
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
        loop {
            Listing::runContinuousListing(initialCodeTrace)
        }
    end
end
