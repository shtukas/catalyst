
class Speedometer
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

    # Listing::listingPositioningAsString(item)
    def self.listingPositioningAsString(item)
        return "" if ["NxCore", "NxTask"].include?(item["mikuType"])
        return "" if item["listing-positioning-2141"].nil?
        positioning = " [#{Time.at(item["listing-positioning-2141"]).to_s}]"
        if Time.at(item['listing-positioning-2141']).to_s[0, 10] == CommonUtils::today() then
            positioning = positioning.yellow
        end
        if item['listing-positioning-2141'] < Time.new.to_i then
            positioning = positioning.red
        end
        positioning
    end

    # Listing::toString2(store, item)
    def self.toString2(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "      "
        line = "#{storePrefix}#{Listing::listingPositioningAsString(item)} #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{PolyFunctions::donationSuffix(item)}#{PolyFunctions::parentingSuffix(item)}#{PolyFunctions::engineSuffix(item)}"

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
        items = ListingPositioning::itemsInOrder() # items with a listing position
        if !Config::isPrimaryInstance() then
            items = items.reject{|item| item["mikuType"] == "NxBackup" } # we only show backup items on alexandra
        end
        unixtime = CommonUtils::unixtimeAtComingMidnightAtLocalTimezone()
        items = items.select{|item| item["listing-positioning-2141"] < unixtime } # we keep items with a deadline today, not afterwards
        i1s, i2s = items.partition{|item| item['listing-positioning-2141'] < Time.new.to_i } # we split today in before and after now
        items =
            i1s                      + # items today, late running
            NxTasks::listingPhase1() + # items with a time commitment engine
            NxTasks::listingPhase2() + # items entirely managed by a core
            NxCores::listingItems()  + # cores
            NxTasks::listingPhase3() + # infinity items without engine
            i2s                        # items today, near future
        items = Desktop::listingItems() + items + NxBalls::activeItems()
        items
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
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

    # Listing::listing(initialCodeTrace)
    def self.listing(initialCodeTrace)
        loop {

            Listing::preliminaries(initialCodeTrace)

            t1 = Time.new.to_f

            items = Listing::itemsForListing()
            items = Prefix::addPrefix(items)

            #system("clear")

            store = ItemStore.new()

            puts "-" * (CommonUtils::screenWidth() - 2)

            items
                .take(CommonUtils::screenHeight()-4)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    line = Listing::toString2(store, item)
                    puts line
                }

            puts "(rendered in #{(Time.new.to_f - t1).round(3)} s)"

            input = LucilleCore::askQuestionAnswerAsString("> ")

            if input == "exit" then
                return
            end

            if input == "game1" then
                Listing::game1()
                next
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
            Listing::listing(initialCodeTrace)
        }
    end

    # Listing::game1()
    def self.game1()
        loop {
            system('clear')
            t1 = Time.new.to_f
            items = Listing::itemsForListing()
            store = ItemStore.new()
            items = items.take(1)
            items = Prefix::addPrefix(items)
            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    line = Listing::toString2(store, item)
                    puts line
                }
            puts "(game1: rendered in #{(Time.new.to_f - t1).round(3)} s)"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            if input == "exit" then
                return
            end
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
