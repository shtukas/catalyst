
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

    # Listing::itemsForListing()
    def self.itemsForListing()
        Timings::lap("17:25")
        i1 = Items::mikuType("NxStackPriority")
        Timings::lap("17:26")
        i2 = Anniversaries::listingItems()
        Timings::lap("17:27")
        i3 = Waves::listingItemsInterruption()
        Timings::lap("17:28")
        i4 = NxBackups::listingItems()
        Timings::lap("17:29")
        i5 = NxDateds::listingItems()
        Timings::lap("17:30")
        i6 = NxFloats::listingItems()
        Timings::lap("17:31")
        i8 = Waves::listingItemsNonInterruption()
        Timings::lap("17:33")
        i9 = NxTasks::activeItemsForListing()
        Timings::lap("17:34")
        i10 = NxTasks::itemsForListing()
        Timings::lap("17:35")

        (i1 + i2 + i3 + i4 + i5 + i6 + i8 + i9 + i10)
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

        Operations::pickUpBufferIn()
    end

    # Listing::get_mode()
    def self.get_mode()
        mode = XCache::getOrNull("74ec18a3-5f93-42f9-a178-a7be7088457f")
        return "normal" if mode.nil?
        mode
    end

    # Listing::set_mode(mode)
    def self.set_mode(mode)
        XCache::set("74ec18a3-5f93-42f9-a178-a7be7088457f", mode)
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

        if items.empty? then
            puts "moon 🚀 : #{IO.read("#{Config::pathToCatalystDataRepository()}/sink.txt")}"
        end

        if Config::isPrimaryInstance() then
            if items.empty? then
                if Listing::get_mode() == "normal" then
                    Listing::set_mode("moon")
                end
            else
                if Listing::get_mode() == "moon" then
                    Listing::set_mode("normal")
                    system("#{Config::userHomeDirectory()}/Galaxy/DataHub/Binaries/pamela 'catalyst' 'moon: I have something...'")
                end
            end
        end

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
