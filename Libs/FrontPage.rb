class FrontPage

    # -----------------------------------------
    # Data

    # FrontPage::canBeDefault(item)
    def self.canBeDefault(item)
        return false if TmpSkip1::isSkipped(item)
        return true if NxBalls::itemIsRunning(item)
        return false if TmpSkip1::isSkipped(item)
        return false if item["mikuType"] == "TxCondition"
        true
    end

    # FrontPage::isInterruption(item)
    def self.isInterruption(item)
        item["interruption"]
    end

    # FrontPage::toString2(store, item)
    def self.toString2(store, item)
        # Edits to this function should be mirrored in ListingService::decideListingLines(item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : ""
        hasChildren = Parenting::hasChildren(item["uuid"]) ? " [children]".red : ""
        parentingSuffix = Parenting::suffix(item)
        if item["mikuType"] == "NxTask" then
            parentingSuffix = ""
        end

        lines = []
        line = "#{storePrefix} #{PolyFunctions::toString(item)}#{UxPayload::suffix_string(item)}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{Donations::donationSuffix(item)}#{parentingSuffix}#{DoNotShowUntil::suffix2(item)}#{hasChildren}"

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.yellow
        end

        if NxBalls::itemIsRunning(item) then
            line = line.green
        end

        lines << line

        if item["uxpayload-b4e4"] and item["uxpayload-b4e4"]["type"] == "breakdown" then
            item["uxpayload-b4e4"]["lines"].each{|l|
                lines << "         ✏︎ #{l}"
            }
        end

        lines
    end

    # -----------------------------------------
    # Ops

    # FrontPage::preliminaries(initialCodeTrace)
    def self.preliminaries(initialCodeTrace)
        if CommonUtils::catalystTraceCode() != initialCodeTrace then
            puts "Code change detected"
            exit
        end

        Operations::dispatchPickUp()
    end

    # FrontPage::displayListingOnce()
    def self.displayListingOnce()
        store = ItemStore.new()
        printer = lambda{|line| puts line }
        printer.call("")

        sheight = CommonUtils::screenHeight()
        swidth = CommonUtils::screenWidth()

        # Automatic Scheduled Maintenance

        if XCacheExensions::trueNoMoreOftenThanNSeconds("e1450d85-3f2b-4c3c-9c57-5e034361e8d5", 40000) then
            puts "Running global maintenance (every half a day)"
            Operations::globalMaintenance()
            XCache::set("e1450d85-3f2b-4c3c-9c57-5e034361e8d5", Time.new.to_i)
        end

        if XCacheExensions::trueNoMoreOftenThanNSeconds("80f6dfde-ccca-4ee4-b0e4-9d93794fac5e", 3600) then
            puts "Running listing maintenance (every hour)"
            ListingService::maintenance()
            XCache::set("80f6dfde-ccca-4ee4-b0e4-9d93794fac5e", Time.new.to_i)
        end

        # Palmer reporting

        performance = `palmer report:performance`.strip
        i = performance.index('(')
        percentage = performance[i, 10].to_f
        if percentage < 100 then
            puts performance.red
        else
            if percentage < 120 then
                puts performance.yellow
            end
        end

        t1 = Time.new.to_f

        # Main listing

        activePackets = NxBalls::activePackets()
        activePackets
            .sort_by{|packet| packet["startunixtime"] }
            .reverse
            .map{|packet| packet["item"] }
            .each{|item|
                store.register(item, FrontPage::canBeDefault(item))
                lines = FrontPage::toString2(store, item)
                lines.each{|line|
                    printer.call(line.green)
                }
                lines.each{|line|
                    sheight = sheight - (line.size/swidth + 1)
                }
                break if sheight <= 4
            }

        entries = ListingService::entriesForListing(activePackets.map{|px| px["item"]["uuid"]})
        entries = CommonUtils::removeDuplicateObjectsOnAttribute(entries, "itemuuid")
        entries
            .each{|entry|
                item = entry["item"]

                # Display the children
                Prefix::prefix(item).each{|child|
                    child['x:is-prefix'] = true
                    store.register(child, FrontPage::canBeDefault(child))
                    lines = FrontPage::toString2(store, child)
                    if NxBalls::itemIsRunning(child) then
                        lines = lines.map{|line| line.green }
                    end
                    lines.each{|line|
                        printer.call(line)
                        sheight = sheight - (line.size/swidth + 1)
                    }
                }
                store.register(item, FrontPage::canBeDefault(item))
                lines = entry["listing_lines"]

                # Display the first line
                line = lines.shift
                line = line.gsub("STORE-PREFIX", "(#{store.prefixString()})")
                if entry["position"] then
                    line = line + " (#{entry["position"]})".yellow
                end
                if NxBalls::itemIsRunning(item) then
                    line = line.green
                end
                printer.call(line)
                sheight = sheight - (line.size/swidth + 1)
                break if sheight <= 3

                # Display the other lines
                lines.each{|line|
                    printer.call(line)
                    sheight = sheight - (line.size/swidth + 1)
                    break if sheight <= 3
                }
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
                sleep 300
                LucilleCore::locationsAtFolder("#{Config::pathToCatalystDataRepository()}/items-destroyed")
                    .select{|filepath| filepath[-4, 4] == ".txt" }
                    .each{|filepath|
                        uuid = IO.read(filepath).strip
                        status = Datablocks::removeUUID(uuid)
                        if status and File.exist?(filepath) then
                            FileUtils.rm(filepath)
                        end
                    }
            }
        }

        loop {
            FrontPage::preliminaries(initialCodeTrace)
            FrontPage::displayListingOnce()
        }
    end
end
