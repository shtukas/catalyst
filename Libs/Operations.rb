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
                    puts FrontPage::toString2(store, item)
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
        puts "BankVault::maintenance()"
        BankVault::maintenance()
        puts "Items::maintenance()"
        Items::maintenance()
    end

    # Operations::interactivelyGetLinesUsingTextEditor()
    def self.interactivelyGetLinesUsingTextEditor()
        text = CommonUtils::editTextSynchronously("").strip
        return [] if text == ""
        text
            .lines
            .map{|line| line.strip }
            .select{|line| line != "" }
    end

    # Operations::interactivelyGetLinesUsingTerminal()
    def self.interactivelyGetLinesUsingTerminal()
        lines = []
        loop {
            line = LucilleCore::askQuestionAnswerAsString("entry (empty to abort): ")
            break if line.size == 0
        }
        lines
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
        NxPolymorphs::doNotShowUntil(item, unixtime)
    end

    # Operations::expose(item)
    def self.expose(item)
        puts JSON.pretty_generate(item)
        puts ""
        puts "front page line: #{FrontPage::toString2(ItemStore.new(), item)}"
        LucilleCore::pressEnterToContinue()
    end

    # Operations::dispatchPickUp()
    def self.dispatchPickUp()
        pathToCatalyst = "#{Config::pathToGalaxy()}/DataHub/Catalyst"

        LucilleCore::locationsAtFolder("#{pathToCatalyst}/Dispatch/NxTask")
            .select{|location| File.basename(location)[0, 1] != "." }
            .each{|location|
                puts location.yellow
                description = File.basename(location)
                item = NxTasks::locationToTask(description, location)
                LucilleCore::removeFileSystemLocation(location)
            }

        directory = "#{pathToCatalyst}/Dispatch/Today"
        if !File.exist?(directory) then
            puts "I cannot see: #{directory}. Exit"
            exit
        end
        LucilleCore::locationsAtFolder(directory)
            .select{|location| File.basename(location)[0, 1] != "." }
            .each{|location|
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
        LucilleCore::locationsAtFolder(directory)
            .select{|location| File.basename(location)[0, 1] != "." }
            .each{|location|
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
            projects = NxProjects::listingItems()
            items = [ondates, projects].flatten
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|i| PolyFunctions::toString(i) })
            break if item.nil?
            PolyActions::access(item)
            PolyActions::editDescription(item)
        }
    end

    # Operations::morning()
    def self.morning()
        system('clear')
        puts "We start with front renames (if needed)".green
        Operations::frontRenames()

        system('clear')
        puts "Input things you want/need to do today".green
        want1 = Operations::interactivelyGetLinesUsingTerminal()
            .reverse
            .map{|line|
                puts "processing: #{line}".green
                item = NxLines::issue(line)
                # TODO
                item
            }

        system('clear')
        puts "We now select the items we really need to do or work on today (on dates)".green
        ondates, _ = LucilleCore::selectZeroOrMore("NxOnDates", [], NxOnDates::listingItems(), lambda{|i| PolyFunctions::toString(i) })

        system('clear')
        puts "We now select the items we really need to do or work on today (projects)".green
        projects, _ = LucilleCore::selectZeroOrMore("NxProjects", [], NxProjects::listingItems(), lambda{|i| PolyFunctions::toString(i) })

        system('clear')
        puts "We now select the items we really need to do or work on today (waves)".green
        waves, _ = LucilleCore::selectZeroOrMore("Waves", [], Waves::nonInterruptionItemsForListing(), lambda{|i| PolyFunctions::toString(i) })

        system('clear')
        puts "We now select the items we really need to do or work on today (tasks)".green
        tasks, _ = LucilleCore::selectZeroOrMore("NxTasks", [], NxTasks::tasksInOrder(), lambda{|i| PolyFunctions::toString(i) })

        system('clear')
        puts "Input things you want/need to do today".green
        want2 = Operations::interactivelyGetLinesUsingTerminal()
            .reverse
            .map{|line|
                puts "processing: #{line}".green
                item = NxLines::issue(line)
                # TODO
                item
            }

        items = [Waves::listingItemsInterruption(), want1, want2, ondates, projects, waves, tasks].flatten

        system('clear')
        puts "general ordering".green
        e1, e2 = LucilleCore::selectZeroOrMore("items", [], items, lambda{|i| PolyFunctions::toString(i) })
        items = e1 + e2
        items.reverse.each{|item|
            position = 0.9 * [0.20].min
            px17 = {
                "type"  => "overriden",
                "value" => position,
                "expiry"=> CommonUtils::unixtimeAtComingMidnightAtLocalTimezone()
            }
        }
    end

    # Operations::postponeToTomorrowOrDestroy(item)
    def self.postponeToTomorrowOrDestroy(item)
        puts PolyFunctions::toString(item).green
        options = ["postpone to tomorrow (default)", "destroy"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        if option.nil? or option == "postpone to tomorrow (default)" then
            NxPolymorphs::doNotShowUntil(item, CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone())
        end
        if option == "destroy" then
            Items::deleteItem(item["uuid"])
        end
    end

    # Operations::issuePriority(description)
    def self.issuePriority(description)
        item = NxLines::issue(description)
        return if item.nil?
        NxBalls::activeItems().each{|i|
            NxBalls::pause(i)
        }
        # TODO
        if LucilleCore::askQuestionAnswerAsBoolean("start ? ", true) then
            PolyActions::start(item)
        end
    end

    # Operations::program3ItemsWithGivenBehaviour(btype)
    def self.program3ItemsWithGivenBehaviour(btype)
        Operations::program3(lambda { Items::mikuType("NxPolymorph").select{|item| NxPolymorphs::itemHasBehaviour(item, btype) } })
    end
end
