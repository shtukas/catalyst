
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

    # Listing::ratioPrefix(item)
    def self.ratioPrefix(item)
        return "" if item["mikuType"] == "NxStrat"
        return "" if item["mikuType"] == "NxTask" and !NxTasks::isActive(item) # those come from Prefixing
        metric = ListingMetric::metric(item)
        return "" if metric.nil?
        "(#{"%5.3f" % metric}) "
    end

    # Regular main listing 
    # Listing::toString2(store, item)
    def self.toString2(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "      "
        line = "#{Listing::ratioPrefix(item)}#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{PolyFunctions::parentingSuffix(item)}#{DoNotShowUntil::suffix(item)}"

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
        items = [
            Anniversaries::listingItems(),
            NxBackups::listingItems(),
            NxDateds::listingItems(),
            NxFloats::listingItems(),
            NxCores::listingItems(),
            NxTasks::activeItemsForListing(),
            Waves::listingItems(),
            NxMonitors::listingItems(),
            Items::mikuType("NxStackPriority")
        ]
            .flatten

        itemsListing = []
        itemsSituations = []

        items.each{|item|
            if item["flight-1753"] and item["flight-1753"]["version"].nil? then
                itemsListing << item
                next
            end
            if item["flight-1753"] and item["flight-1753"]["version"] == 2 then
                itemsListing << item
                next
            end
            if item["flight-1753"] and item["flight-1753"]["version"] == 3 then
                itemsSituations << item
                next
            end
            itemsListing << item
        }

        i1s = itemsListing
                .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                .sort_by{|item| ListingMetric::metric(item) }

        situations = itemsSituations.map{|item| item["flight-1753"]["situation"] }.uniq

        {
            "listingItems" => i1s,
            "situations" => situations
        }
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

        package = Listing::itemsForListing()

        Timings::lap("17:30")

        items = package["listingItems"]
        situations = package["situations"]

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

        situations.each{|situation|
            l = lambda {
                l2 = lambda {
                    Items::items()
                        .select{|item| item["flight-1753"] and item["flight-1753"]["version"] == 3 and item["flight-1753"]["situation"] == situation }
                        .sort_by{|item| item["flight-1753"]["unixtime"] }
                }
                Operations::program3(l2)
            }
            item = NxLambdas::interactivelyIssueNewOrNull("situation: #{situation}", l)
            store.register(item, false)
            line = Listing::toString2(store, item)
            printer.call(line)
        }

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
