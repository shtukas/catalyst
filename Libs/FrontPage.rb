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

        line = "#{storePrefix}#{(item["is-priority-02"] and item["is-priority-02"].include?(CommonUtils::today())) ? " 🔥 " : " "}#{PolyFunctions::toString(item)}#{UxPayloads::suffixString(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{TimeCores::suffix(item)}#{Donations::suffix(item)}#{DoNotShowUntil::suffix(item)}"

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

    # FrontPage::itemToBlockId(item)
    def self.itemToBlockId(item)
        if item["uuid"] == "5b1d0568-28e6-4613-b012-7e4e497baed7" then # trading
            return "68195738-ff92-4579-9af9-28969f858f3a"
        end
        if item["mikuType"] == "Wave" and !item["interruption"] then
            return "955f4d23-03ac-4da1-8eb3-7413d2f8a6a4"
        end
        if item["mikuType"] == "NxActive" then
            return "c28bf563-5754-4e02-8fa1-82ee0f5ad584"
        end
        if item["mikuType"] == "NxTask" then
            return "1cfc792f-28e8-46d4-9667-c2f96a928e01"
        end
        if item["mikuType"] == "BufferIn" then
            return "d64da179-576a-41ba-a6a4-efa1640bcf51"
        end
        "8ee59d48-c0a9-40d8-bdee-d62b20422409" # the complement
    end

    # FrontPage::structure()
    def self.structure()
        ratio_given_expectation = lambda {|uuid, hours_to_1|
            BankDerivedData::recoveredAverageHoursPerDay(uuid).to_f/hours_to_1
        }

        palmer_trading = Blades::itemOrNull("5b1d0568-28e6-4613-b012-7e4e497baed7")

        [
            {
                "name" => "BufferIn",
                "ratio" => ratio_given_expectation.call("d64da179-576a-41ba-a6a4-efa1640bcf51", 1), # BufferIn
                "items" => BufferIn::listingItems()
            },
            {
                "name" => "Palmer Trading",
                "ratio" => ratio_given_expectation.call("68195738-ff92-4579-9af9-28969f858f3a", palmer_trading["timecore-57"]["day-expectation-hours"]), # Palmer Trading
                "items" => [palmer_trading]
            },
            {
                "name" => "Waves (non interruption)",
                "ratio" => ratio_given_expectation.call("955f4d23-03ac-4da1-8eb3-7413d2f8a6a4", 2), # non interruption waves
                "items" => Waves::listingItemsNonInterruption()
            },
            {
                "name" => "NxActives",
                "ratio" => ratio_given_expectation.call("c28bf563-5754-4e02-8fa1-82ee0f5ad584", 3), # NxActives
                "items" => NxActives::listingItems()
            },
            {
                "name" => "NxTasks",
                "ratio" => ratio_given_expectation.call("1cfc792f-28e8-46d4-9667-c2f96a928e01", 2), # NxTasks
                "items" => NxTasks::listingItems()
            }
        ]
        .sort_by{|packet| packet["ratio"] }
    end

    # FrontPage::itemsForListingOrdered()
    def self.itemsForListingOrdered()
        [
            Blades::items().select{|item| item["is-priority-02"] and item["is-priority-02"].include?(CommonUtils::today()) }.sort_by{|item| item["global-pos-07"] || 0},
            Waves::listingItemsInterruption(),
            NxOndates::listingItems(),
            NxBackups::listingItems(),
            NxCounters::listingItems(),
            FrontPage::structure().map{|packet| packet["items"] }.flatten
        ]
            .flatten
            .select{|item| DoNotShowUntil::isVisible(item) }
            .select{|item| FrontPage::isAccessible(item) }
    end

    # FrontPage::displayListing(initialCodeTrace)
    def self.displayListing(initialCodeTrace)
        store = ItemStore.new()
        puts ""

        sheight = CommonUtils::screenHeight() - 5
        swidth = CommonUtils::screenWidth()

        if Config::isPrimaryInstance() then
            if (Time.new.to_i - XCache::getOrDefaultValue("e1450d85-3f2b-4c3c-9c57-5e034361e8d6", "0").to_i) > 86400 then
                Operations::globalMaintenance()
                XCache::set("e1450d85-3f2b-4c3c-9c57-5e034361e8d6", Time.new.to_i)
            end
        end

        # ----------------------------------------------------------------------
        # Main listing

        t1 = Time.new.to_f

        if !XCache::getFlag("818EA198-B8C0-4C28-96F6-BADCFB330FB6:#{CommonUtils::today()}") then
            puts "      ☀️  run morning"
        end
        begin
            (lambda{
                path_to_palmer = "/Users/pascal_honore/Galaxy/Palmer/binaries/palmer"
                if File.exist?(path_to_palmer) then
                    # {"today_pl":1.0,"last_three_days_pl":1.0,"performance":1.0}
                    performance = JSON.parse(`#{path_to_palmer} performance`)
                    if performance["today_pl"] < 100 then
                        puts "      🧧 palmer missing pl for today: #{(100 - performance["today_pl"]).round(2)} USD"
                        return
                    end
                    if performance["last_three_days_pl"] < 300 then
                        puts "      🧧 palmer missing pl over 3 days: #{(300 - performance["last_three_days_pl"]).round(2)} USD"
                        return
                    end
                    puts "      🧧 performance: #{(100 * performance["performance"]).round(2)} %"
                end
            }).call()
        rescue
            puts "palmer: problem extracting performance"
        end

        items = CommonUtils::removeDuplicateObjectsOnAttribute(NxBalls::activeItems() + FrontPage::itemsForListingOrdered(), "uuid")

        items.each{|item|
            store.register(item, FrontPage::canBeDefault(item))
            line = FrontPage::toString2(store, item, true)
            puts line
            sheight = sheight - (line.size/swidth + 1)
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
