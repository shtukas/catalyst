class Operations

    # Operations::editItemJson(item)
    def self.editItemJson(item)
        # This function edit the payload, if there is now
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.each{|k, v|
            Items::setAttribute(item["uuid"], k, v)
        }
    end

    # Operations::editItemPayload(item)
    def self.editItemPayload(item)
        if item["uxpayload-b4e4"].nil? then
            puts "I could not find a payload on '#{PolyFunctions::toString(item)}'"
            LucilleCore::pressEnterToContinue()
            return
        end
        payload = UxPayload::edit(item["uuid"], item["uxpayload-b4e4"])
        return if payload.nil?
        Items::setAttribute(item["uuid"], "uxpayload-b4e4", payload)
    end

    # Operations::editItem(item)
    def self.editItem(item)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["edit description", "edit payload", "edit json"])
        return if option.nil?
        if option == "edit description" then
            PolyActions::editDescription(item)
        end
        if option == "edit payload" then
            Operations::editItemPayload(item)
        end
        if option == "edit json" then
            Operations::editItemJson(item)
        end
        ListingService::evaluate(item["uuid"])
    end

    # Operations::program3(lx)
    def self.program3(lx)
        loop {
            elements = lx.call()
            store = ItemStore.new()
            puts ""
            elements
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
                    FrontPage::toString2(store, item).each {|line|
                        puts line
                    }
                }
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Operations::globalMaintenance()
    def self.globalMaintenance()
        puts "NxTasks::maintenance()"
        NxTasks::maintenance()
        puts "ListingService::maintenance()"
        ListingService::maintenance()
        puts "BankVault::maintenance()"
        BankVault::maintenance()
        puts "Items::maintenance()"
        Items::maintenance()
    end

    # Operations::interactivelyGetLines()
    def self.interactivelyGetLines()
        text = CommonUtils::editTextSynchronously("").strip
        return [] if text == ""
        text
            .lines
            .map{|line| line.strip }
            .select{|line| line != "" }
    end

    # Operations::interactivelyRecompileLines(lines)
    def self.interactivelyRecompileLines(lines)
        text = CommonUtils::editTextSynchronously(lines.join("\n")).strip
        return [] if text == ""
        text
            .lines
            .map{|line| line.strip }
            .select{|line| line != "" }
    end

    # Operations::interactivelyPush(item)
    def self.interactivelyPush(item)
        PolyActions::stop(item)
        puts "push '#{PolyFunctions::toString(item).green}'"
        unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
        return if unixtime.nil?
        puts "pushing until '#{Time.at(unixtime).to_s.green}'"
        PolyActions::doNotShowUntil(item, unixtime)
    end

    # Operations::expose(item)
    def self.expose(item)
        puts JSON.pretty_generate(item)
        puts ""
        puts "do not show until:"
        unixtime = DoNotShowUntil::getUnixtimeOrNull(item["uuid"])
        puts "  unixtime: #{unixtime}"
        if unixtime then
            puts "  datetime: #{Time.at(unixtime).to_s}"
        end
        puts ""
        puts "listing service entry:"
        entry = ListingService::getEntryOrNull(item["uuid"])
        puts JSON.pretty_generate(entry)
        puts ""
        puts "front page line: #{FrontPage::toString2(ItemStore.new(), item)}"
        LucilleCore::pressEnterToContinue()
    end

    # Operations::dispatchPickUp()
    def self.dispatchPickUp()
        pathToCatalyst = "#{Config::pathToGalaxy()}/DataHub/Catalyst"

        PriorityLevels::levels().each{|level|
            directory = "#{pathToCatalyst}/Dispatch/NxTask/#{level}"
            if !File.exist?(directory) then
                puts "I cannot see: #{directory}. Exit"
                exit
            end
            LucilleCore::locationsAtFolder(directory).each{|location|
                puts location.yellow
                description = File.basename(location)
                item = NxTasks::locationToTask(description, location, level)
                ListingService::evaluate(item["uuid"])
                LucilleCore::removeFileSystemLocation(location)
            }
        }

        directory = "#{pathToCatalyst}/Dispatch/Today"
        if !File.exist?(directory) then
            puts "I cannot see: #{directory}. Exit"
            exit
        end
        LucilleCore::locationsAtFolder(directory).each{|location|
            puts location.yellow
            description = File.basename(location)
            item = NxOnDates::locationToItem(description, location)
            LucilleCore::removeFileSystemLocation(location)
        }

        directory = "#{pathToCatalyst}/Dispatch/Tomorrow"
        if !File.exist?(directory) then
            puts "I cannot see: #{directory}. Exit"
            exit
        end
        LucilleCore::locationsAtFolder(directory).each{|location|
            puts location.yellow
            description = File.basename(location)
            item = NxOnDates::locationToItem(description, location)
            Items::setAttribute(item["uuid"], "date", CommonUtils::tomorrow())
            LucilleCore::removeFileSystemLocation(location)
        }
    end

    # Operations::probeHead()
    def self.probeHead()
        Items::mikuType("NxTask").each{|item|
            #puts "probing item #{item["description"]}"
            next if item["uxpayload-b4e4"].nil?
            if item["uxpayload-b4e4"]["type"] == "Dx8Unit" then
                unitId = item["uxpayload-b4e4"]["id"]
                location = Dx8Units::acquireUnitFolderPathOrNull(unitId)
                puts "unit location: #{location}"
                payload2 = UxPayload::locationToPayload(item["uuid"], location)
                Items::setAttribute(item["uuid"], "uxpayload-b4e4", payload2)
                LucilleCore::removeFileSystemLocation(location)
            end
        }
    end

    # Operations::frontRenames()
    def self.frontRenames()
        loop {
            ondates = NxOnDates::listingItems()
            deadlines = NxDeadlines::listingItems()
            projects = NxProjects::listingItems()
            highs = Items::mikuType("NxTask").select{|item| item["priorityLevel48"] == "high" }
            items = [ondates, deadlines, projects, highs].flatten
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|i| PolyFunctions::toString(i) })
            break if item.nil?
            PolyActions::access(item)
            PolyActions::editDescription(item)
            ListingService::evaluate(item["uuid"])
        }
    end

    # Operations::morning()
    def self.morning()
        puts "We start with front renames (if needed)"
        Operations::frontRenames()

        puts "We now select the items we really need to do or work on today"
        ondates, _ = LucilleCore::selectZeroOrMore("elements", [], NxOnDates::listingItems(), lambda{|i| PolyFunctions::toString(i) })
        deadlines, _ = LucilleCore::selectZeroOrMore("elements", [], NxDeadlines::listingItems(), lambda{|i| PolyFunctions::toString(i) })
        projects, _ = LucilleCore::selectZeroOrMore("elements", [], NxProjects::listingItems(), lambda{|i| PolyFunctions::toString(i) })
        highs = Items::mikuType("NxTask").select{|item| item["priorityLevel48"] == "high" }
        highs, _ = LucilleCore::selectZeroOrMore("elements", [], highs, lambda{|i| PolyFunctions::toString(i) })
        elements = [ondates, deadlines, projects, highs].flatten

        puts "general ordering"
        e1, e2 = LucilleCore::selectZeroOrMore("elements", [], elements, lambda{|i| PolyFunctions::toString(i) })
        elements = e1 + e2
        elements.reverse.each{|item|
            position = 0.9 * [ListingService::firstPositionInDatabase(), 0.20].min
            px17 = {
                "type"  => "overriden",
                "value" => position,
                "expiry"=> CommonUtils::unixtimeAtComingMidnightAtLocalTimezone()
            }
            ListingService::setPx17(item["uuid"], px17)
        }
    end

    # Operations::postponeToTomorrowOrDestroy(item)
    def self.postponeToTomorrowOrDestroy(item)
        options = ["postpone to tomorrow", "destroy"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        if option == "postpone to tomorrow" then
            PolyActions::doNotShowUntil(item, CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone())
            ListingService::removeEntry(item["uuid"])
        end
        if option == "destroy" then
            Items::deleteItem(item["uuid"])
            ListingService::removeEntry(item["uuid"])
        end
    end
end
