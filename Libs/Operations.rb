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
        directory = "#{Config::userHomeDirectory()}/Desktop/Dispatch/Buffer-In"
        if File.exist?(directory) then
            LucilleCore::locationsAtFolder(directory).each{|location|
                puts location.yellow
                description = File.basename(location)
                item = NxTasks::locationToTask(description, location, "high")
                ListingService::evaluate(item["uuid"])
                LucilleCore::removeFileSystemLocation(location)
            }
        end

        directory = "#{Config::userHomeDirectory()}/Desktop/Dispatch/Today"
        if File.exist?(directory) then
            LucilleCore::locationsAtFolder(directory).each{|location|
                puts location.yellow
                description = File.basename(location)
                item = NxOnDates::locationToItem(description, location)
                #puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)
                #puts PolyFunctions::toString(item)
            }
        end

        directory = "#{Config::userHomeDirectory()}/Desktop/Dispatch/Tomorrow"
        if File.exist?(directory) then
            LucilleCore::locationsAtFolder(directory).each{|location|
                puts location.yellow
                description = File.basename(location)
                item = NxOnDates::locationToItem(description, location)
                Items::setAttribute(item["uuid"], "date", CommonUtils::tomorrow())
                #puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)
                #puts PolyFunctions::toString(item)
            }
        end
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
end
