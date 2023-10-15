
=begin
nx1 = {
    "nx2"  : {"state": "seeking"} { "state": "pending" } { "state": "running", "start-unixtime": float } { "state": "completed", "start-unixtime": float } { "state": "exit" }
    "item" : nil or Item
}
=end

# Blocks
#   1: Now                 :
#   2: Non important waves : 48d8bde7-8033-4377-bbfc-2ea7918a150d
#   3: Ondates             : f6fd957b-8d62-45e4-9290-6b0f78e27599
#   4: Tasks               : 646884a0-4625-46e7-9de3-e9ebadcadc21

class Stream

    # Stream::block1()
    def self.block1()
        [
            DropBox::items(),
            PhysicalTargets::listingItems(),
            Anniversaries::listingItems(),
            Waves::listingItems().select{|item| item["interruption"] }
        ]
            .flatten
            .reject{|item| item["mikuType"] == "NxThePhantomMenace" }
            .select{|item| Listing::listable(item) }
    end

    # Stream::block2()
    def self.block2()
        [
            Waves::listingItems().select{|item| !item["interruption"] }
        ]
            .flatten
            .map{|item|
                item["10fd0f74-03e8"] = {
                    "description" => "non important waves",
                    "number"      => "48d8bde7-8033-4377-bbfc-2ea7918a150d"
                }
                item
            }
    end

    # Stream::block3()
    def self.block3()
        [
            NxOndates::listingItems(),
        ]
            .flatten
            .map{|item|
                item["10fd0f74-03e8"] = {
                    "description" => "ondate",
                    "number"      => "f6fd957b-8d62-45e4-9290-6b0f78e27599"
                }
                item
            }
    end

    # Stream::block4()
    def self.block4()
        [
            Catalyst::redItems(),
            Config::isPrimaryInstance() ? Backups::listingItems() : [],
            NxTasks::orphans(),
            Engined::listingItems()
        ]
            .flatten
            .map{|item|
                item["10fd0f74-03e8"] = {
                    "description" => "tasks",
                    "number"      => "646884a0-4625-46e7-9de3-e9ebadcadc21"
                }
                item
            }
    end

    # Stream::blocksInOrder()
    def self.blocksInOrder()
        [
            {
                "name"    => "block 2: non important waves",
                "items"   => Stream::block2(),
                "account" => "48d8bde7-8033-4377-bbfc-2ea7918a150d"
            },
            {
                "name"    => "block 3: ondates",
                "items"   => Stream::block3(),
                "account" => "f6fd957b-8d62-45e4-9290-6b0f78e27599"
            },
            {
                "name"    => "block 4: tasks",
                "items"   => Stream::block4(),
                "account" => "646884a0-4625-46e7-9de3-e9ebadcadc21"
            },
        ]
            .sort_by {|packet| Bank::recoveredAverageHoursPerDay(packet["account"]) }
    end

    # Stream::items()
    def self.items()
        items = Stream::blocksInOrder()
                    .map{|packet| packet["items"] }
                    .flatten

        (Stream::block1() + items)
            .reject{|item| item["mikuType"] == "NxThePhantomMenace" }
            .select{|item| Listing::listable(item) }
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
    end

    # Stream::toString3(item)
    def self.toString3(item)
        toString = Listing::redRewrite(item, PolyFunctions::toString(item))
        "#{toString}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DoNotShowUntil::suffixString(item)}#{OpenCycles::suffix(item)}#{TxCores::suffix(item)}"
    end

    # Stream::seek() # item or nil
    def self.seek()
        item = Stream::items().first
        if item["mikuType"] == "NxThread" then
            item = NxThreads::childrenInOrder(item).first
        end
        item
    end

    # Stream::oldStyleLoop()
    def self.oldStyleLoop()
        loop {
            system('clear')
            puts ""
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)
            store = ItemStore.new()
            Listing::items()
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    line = Listing::toString2(store, item)
                    status = spacecontrol.putsline line
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"

            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Stream::activateAndTerminate(nx1)
    def self.activateAndTerminate(nx1)
        raise "(error: 7c48000d-cc6e-4dc6-bb89-6ae91601e532): #{nx1}" if nx1["nx2"]["state"] != "running"

        item = nx1["item"]

        if item["mikuType"] == "PhysicalTarget" then
            PolyActions::access(item)
            nx1["nx2"]["state"] = "completed"
            return nx1
        end
        if item["mikuType"] == "Backup" then
            XCache::set("1c959874-c958-469f-967a-690d681412ca:#{item["uuid"]}", Time.new.to_i)
            nx1["nx2"]["state"] = "completed"
            return nx1
        end
        if item["mikuType"] == "Wave" then
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("#{Time.new.utc.iso8601.red}: #{Waves::toString(item).green}: for done-ing: ", true) then
                Waves::performWaveDone(item)
                nx1["nx2"]["state"] = "completed"
            end
            return nx1
        end
        if item["mikuType"] == "NxTask" then
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{PolyFunctions::toString(item).green}' ? ", false) then
                Catalyst::destroy(item["uuid"])
                nx1 = {
                    "nx2"   => { "state" => "seeking" },
                    "item"  => nil
                }
            else
                if item["parent-1328"].nil? and item["engine-0916"].nil? then
                    NxThreads::interactivelySelectAndInstallInThread(item)
                end
                nx1["nx2"]["state"] = "completed"
            end
            return nx1
        end

        raise "(error: ac6f-c5bad8fb5527) could not do: #{item}"
    end

    # Stream::processState(nx1)
    def self.processState(nx1)

        puts JSON.pretty_generate(nx1)

        if nx1["nx2"]["state"] == "seeking" then
            item = Stream::seek()
            if item.nil? then
                nx1["nx2"] = { "state" => "exit" }
                return nx1
            end
            nx1["item"] = item
            nx1["nx2"] = { "state" => "pending" }
            return nx1
        end

        if nx1["nx2"]["state"] == "pending" then
            item = nx1["item"]
            s1 = item["10fd0f74-03e8"] ? " (#{item["10fd0f74-03e8"]["description"]}, #{"%6.2f" % Bank::recoveredAverageHoursPerDay(item["10fd0f74-03e8"]["number"])})" : ""
            print "#{Time.new.utc.iso8601.red}: #{Stream::toString3(item).green}#{NxThreads::suffix(item)}#{s1}: [enter] to start, or 'done', or +timecode, or 'listing', ': "
            input = STDIN.gets().strip
            if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                nx1 = {
                    "nx2"   => { "state" => "seeking" },
                    "item"  => nil
                }
                return nx1
            end
            if input == "listing" then
                Stream::oldStyleLoop()
                nx1 = {
                    "nx2"   => { "state" => "seeking" },
                    "item"  => nil
                }
                return nx1
            end
            if input == 'done' then
                PolyActions::done(item)
                nx1 = {
                    "nx2"   => { "state" => "seeking" },
                    "item"  => nil
                }
                return nx1
            end
            if input == "'" then
                puts "blocks, >thread"
                LucilleCore::pressEnterToContinue()
                return nx1
            end
            if input == '>thread' then
                NxThreads::interactivelySelectAndInstallInThread(item)
                nx1 = {
                    "nx2"   => { "state" => "seeking" },
                    "item"  => nil
                }
                return nx1
            end
            if input == "blocks" then
                if Stream::block1().size > 0 then
                    puts "block 1: #{"now".ljust(21)}: (active: #{Stream::block1().size} items)"
                end
                Stream::blocksInOrder()
                .select{|block| block["items"].size > 0 }
                .each{|block|
                    puts "#{block["name"].ljust(30)}: rt: #{"%6.2f" % Bank::recoveredAverageHoursPerDay(block["account"])}"
                }
                LucilleCore::pressEnterToContinue()
                return nx1
            end
            if input != "" then
                return nx1
            end
            nx1["nx2"] = { "state" => "running", "start-unixtime" => Time.new.to_i }
            nx1 = Stream::activateAndTerminate(nx1)
            return nx1
        end

        if nx1["nx2"]["state"] == "running" then
            item = nx1["item"]
            print "#{Time.new.utc.iso8601.red}: #{Stream::toString3(item).green}#{NxThreads::suffix(item)}: [enter] to terminate: "
            return nx1
        end

        if nx1["nx2"]["state"] == "completed" then
            item = nx1["item"]
            unixtime = nx1["nx2"]["start-unixtime"]
            timespan = Time.new.to_i - unixtime
            PolyFunctions::itemToBankingAccounts(item).each{|account|
                puts "adding #{timespan} seconds to #{account["description"]}"
                Bank::put(account["number"], timespan)
            }
            nx1 = {
                "nx2"   => { "state" => "seeking" },
                "item"  => nil
            }
            return nx1
        end
    end

    # Stream::main()
    def self.main()

        initialCodeTrace = CommonUtils::catalystTraceCode()

        latestCodeTrace = initialCodeTrace

        Listing::checkForCodeUpdates()

        Thread.new {
            loop {
                sleep 300
                Listing::checkForCodeUpdates()
            }
        }

        nx1 = {
            "nx2"   => { "state" => "seeking" },
            "item"  => nil
        }

        loop {

            if CommonUtils::catalystTraceCode() != initialCodeTrace then
                puts "Code change detected"
                break
            end

            EventsTimelineProcessor::procesLine()

            if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("fd3b5554-84f4-40c2-9c89-1c3cb2a67717", 3600) then
                Listing::maintenance()
            end

            nx1 = Stream::processState(nx1)
            if nx1["nx2"]["state"] == "exit" then
                puts JSON.pretty_generate(nx1)
                return
            end
        }
    end
end
