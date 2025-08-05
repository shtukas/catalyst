class Operations

    # Operations::editItem(item)
    def self.editItem(item)
        # This function edit the payload, if there is now
        return if item["uxpayload-b4e4"].nil?
        payload = UxPayload::edit(item["uuid"], item["uxpayload-b4e4"])
        return if payload.nil?
        Items::setAttribute(item["uuid"], "uxpayload-b4e4", payload)
    end

    # Operations::program3(lx)
    def self.program3(lx)
        loop {
            elements = lx.call()

            store = ItemStore.new()

            puts ""

            elements
                .each{|item|
                    store.register(item, ListingOps::canBeDefault(item))
                    ListingOps::toString2(store, item).each {|line|
                        puts line
                    }
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            puts ""
            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Operations::globalMaintenance()
    def self.globalMaintenance()
        puts "NxTasks::maintenance()"
        NxTasks::maintenance()
        puts "ListingDatabase::maintenance()"
        ListingDatabase::maintenance()
        puts "BankVault::maintenance()"
        BankVault::maintenance()
        puts "Items::maintenance()"
        Items::maintenance()
        puts "Parenting::maintenance()"
        Parenting::maintenance()
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
        DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
    end

    # Operations::expose(item)
    def self.expose(item)
        puts JSON.pretty_generate(item)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(item["uuid"])
        if unixtime then
            puts "do not show until: #{Time.at(unixtime).to_s} "
        end
        entry = ListingDatabase::getEntryOrNull(item["uuid"])
        puts JSON.pretty_generate(entry)
        LucilleCore::pressEnterToContinue()
    end

    # Operations::interactivelySelectTargetForDonationOrNull()
    def self.interactivelySelectTargetForDonationOrNull()
        targets = NxCores::coresInRatioOrder()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("donation target", targets, lambda{|item| PolyFunctions::toString(item) })
    end

    # Operations::interactivelySetDonation(item) -> Item
    def self.interactivelySetDonation(item)
        target = Operations::interactivelySelectTargetForDonationOrNull()
        return item if target.nil?
        Items::setAttribute(item["uuid"], "donation-1205", target["uuid"])
        Items::itemOrNull(item["uuid"])
    end

    # Operations::dispatchPickUp()
    def self.dispatchPickUp()
        directory = "#{Config::userHomeDirectory()}/Desktop/Dispatch/Buffer-In"
        if File.exist?(directory) then
            LucilleCore::locationsAtFolder(directory).each{|location|
                puts location.yellow
                parentuuid, position = PolyFunctions::makeInfinityuuidAndPositionNearTheTop()
                description = File.basename(location)
                item = NxTasks::locationToTask(description, location, parentuuid, position)
                Parenting::insertEntry(parentuuid, item["uuid"], position)
                ListingDatabase::evaluate(item["uuid"])
                LucilleCore::removeFileSystemLocation(location)
            }
        end

        directory = "#{Config::userHomeDirectory()}/Desktop/Dispatch/Today"
        if File.exist?(directory) then
            LucilleCore::locationsAtFolder(directory).each{|location|
                puts location.yellow
                description = File.basename(location)
                item = NxDateds::locationToItem(description, location)
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
                item = NxDateds::locationToItem(description, location)
                Items::setAttribute(item["uuid"], "date", CommonUtils::tomorrow())
                #puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)
                #puts PolyFunctions::toString(item)
            }
        end

        directory = "#{Config::userHomeDirectory()}/Desktop/Dispatch/Line-Stream"
        if File.exist?(directory) then
            LucilleCore::locationsAtFolder(directory).each{|location|
                puts location.yellow
                description = File.basename(location)
                item = NxLines::locationToLine(description, location)
                ListingDatabase::insertUpdateItemAtPosition(item, 0.21)
                puts JSON.pretty_generate(item)
                LucilleCore::removeFileSystemLocation(location)

            }
        end
    end

    # Operations::interactivelySelectParent()
    def self.interactivelySelectParent()
        targets = NxCores::coresInRatioOrder()
        LucilleCore::selectEntityFromListOfEntities_EnsureChoice("parent", targets, lambda{|item| PolyFunctions::toString(item) })
    end

    # Operations::decideParentAndPosition()
    def self.decideParentAndPosition()
        parent = Operations::interactivelySelectParent()
        return nil if parent.nil?
        position = PolyFunctions::interactivelySelectGlobalPositionInParent(parent)
        [parent["uuid"], position]
    end

    # Operations::diveItem(parent)
    def self.diveItem(parent)
        loop {
            store = ItemStore.new()

            puts ""
            store.register(parent, false)
            ListingOps::toString2(store, parent).each{|line|
                puts line
            }
            puts ""

            Parenting::parentuuidToChildrenInOrder(parent["uuid"])
                .each{|element|
                    store.register(element, ListingOps::canBeDefault(element))
                    ListingOps::toString2(store, element).each{|line|
                        puts line
                    }
                }

            puts ""

            puts "todo (here, with position selection) | pile | position * | sort"

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                position = PolyFunctions::interactivelySelectGlobalPositionInParent(parent)
                todo = NxTasks::interactivelyIssueNewOrNull()
                puts JSON.pretty_generate(todo)
                Parenting::insertEntry(parent["uuid"], todo["uuid"], position)
                ListingDatabase::evaluate(todo["uuid"])
                next
            end

            if input == "pile" then
                Operations::interactivelyGetLines()
                    .reverse
                    .each{|line|
                        position = PolyFunctions::firstPositionInParent(parent) - 1
                        todo = NxTasks::descriptionToTask(line, parent["uuid"], position)
                        puts JSON.pretty_generate(todo)
                        Parenting::insertEntry(parent["uuid"], todo["uuid"], position)
                        ListingDatabase::evaluate(todo["uuid"])
                    }
                next
            end

            if input.start_with?("position") then
                listord = input[8, input.size].strip.to_i
                i = store.get(listord.to_i)
                next if i.nil?
                position = PolyFunctions::interactivelySelectGlobalPositionInParent(parent)
                Parenting::insertEntry(parent["uuid"], i["uuid"], position)
                next
            end

            if input == "sort" then
                itemsInOrder = Parenting::parentuuidToChildrenInOrder(parent["uuid"]).sort_by{|item| Parenting::childPositionAtParentOrZero(parent["uuid"], item["uuid"]) }
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], itemsInOrder, lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    position = PolyFunctions::firstPositionInParent(parent) - 1
                    Parenting::insertEntry(parent["uuid"], i["uuid"], position)
                }
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Operations::probeHead()
    def self.probeHead()
        NxCores::cores()
            .each{|core|
                #puts "probing core #{core["description"]}"
                Parenting::parentuuidToChildrenInOrder(core["uuid"])
                    .first(200)
                    .each{|item|
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
            }
    end
end
