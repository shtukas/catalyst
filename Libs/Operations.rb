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
        puts "Parenting::maintenance()"
        Parenting::maintenance()
        puts "NxThreads::maintenance()"
        NxThreads::maintenance()
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
        parent = Parenting::parentOrNull(item["uuid"])
        puts "parent: #{parent}"
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
                parentuuid, position = PolyFunctions::makeInfinityuuidAndPositionNearTheTop()
                description = File.basename(location)
                item = NxTasks::locationToTask(description, location)
                Parenting::insertEntry(parentuuid, item["uuid"], position)
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

    # Operations::interactivelySelectThread()
    def self.interactivelySelectThread()
        targets = NxThreads::threadsInRatioOrder()
        LucilleCore::selectEntityFromListOfEntities_EnsureChoice("parent", targets, lambda{|item| PolyFunctions::toString(item) })
    end

    # Operations::interactivelySelectThreadOrNull()
    def self.interactivelySelectThreadOrNull()
        targets = NxThreads::threadsInRatioOrder()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", targets, lambda{|item| PolyFunctions::toString(item) })
    end

    # Operations::decideParentAndPosition()
    def self.decideParentAndPosition()
        parent = Operations::interactivelySelectThread()
        position = PolyFunctions::interactivelySelectGlobalPositionInParent(parent)
        [parent, position]
    end

    # Operations::architectParentAndPositionOrNull()
    def self.architectParentAndPositionOrNull()
        parent = Operations::interactivelySelectThreadOrNull()
        if parent.nil? then
            position = PolyFunctions::interactivelySelectGlobalPositionInParent(parent)
            return {
                "parent" => parent,
                "position" => position
            }
        end
        thread = NxThreads::interactivelyIssueNewOrNull()
        if thread then
            position = PolyFunctions::interactivelySelectGlobalPositionInParent(thread)
            return {
                "parent" => thread,
                "position" => position
            }
        end
        nil
    end

    # Operations::diveItem(parent)
    def self.diveItem(parent)
        loop {
            store = ItemStore.new()

            puts ""
            store.register(parent, false)
            FrontPage::toString2(store, parent).each{|line|
                puts line
            }
            puts ""

            Parenting::childrenInOrder(parent["uuid"])
                .each{|element|
                    store.register(element, FrontPage::canBeDefault(element))
                    FrontPage::toString2(store, element).each{|line|
                        puts line
                    }
                }

            puts ""

            commands ="todo (here, with position selection) | pile | position * | sort"

            if parent["mikuType"] == "NxThread" then
                commands ="todo (here, with position selection) | moves | pile | position * | sort"
            end

            puts commands

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "todo" then
                position = PolyFunctions::interactivelySelectGlobalPositionInParent(parent)
                todo = NxTasks::interactivelyIssueNewOrNull()
                puts JSON.pretty_generate(todo)
                Parenting::insertEntry(parent["uuid"], todo["uuid"], position)
                ListingService::evaluate(todo["uuid"])
                next
            end

            if input == "moves" then
                puts "architect a parent, select some elements, and then we are going to put the elements in first positions"
                LucilleCore::pressEnterToContinue()

                thread = NxThreads::architectOrNull()
                return if thread.nil?

                childrenInOrder = Parenting::childrenInOrder(parent["uuid"])
                selected, _ = LucilleCore::selectZeroOrMore("elements", [], childrenInOrder, lambda{|i| PolyFunctions::toString(i) })

                selected.each{|child|
                    position = PolyFunctions::firstPositionInParent(thread) - 1
                    Parenting::insertEntry(thread["uuid"], child["uuid"], position)
                }
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
                        ListingService::evaluate(todo["uuid"])
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
                Operations::sortChildrenOfThisParent(parent)
                next
            end

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

    # Operations::sortChildrenOfThisParent(parent)
    def self.sortChildrenOfThisParent(parent)
        childrenInOrder = Parenting::childrenInOrder(parent["uuid"]).sort_by{|item| Parenting::childPositionAtParentOrZero(parent["uuid"], item["uuid"]) }
        return if childrenInOrder.empty?
        selected, _ = LucilleCore::selectZeroOrMore("elements", [], childrenInOrder, lambda{|i| PolyFunctions::toString(i) })
        selected.reverse.each{|i|
            position = PolyFunctions::firstPositionInParent(parent) - 1
            Parenting::insertEntry(parent["uuid"], i["uuid"], position)
            ListingService::ensure(i)
        }
    end

    # Operations::generalSort(item)
    def self.generalSort(item)
        if item["mikuType"] == "NxThread" then
            Operations::sortChildrenOfThisParent(item)
            return
        end
        if item["mikuType"] == "NxTask" then
            Operations::sortChildrenOfThisParent(item)
            return
        end
        puts "[486e8bd8] I do not know how to sort mikuType: #{item["mikuType"]}"
        LucilleCore::pressEnterToContinue()
    end

    # Operations::probeHead()
    def self.probeHead()
        NxThreads::threads()
            .each{|thread|
                #puts "probing thread #{thread["description"]}"
                Parenting::childrenInOrder(thread["uuid"])
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

    # Operations::expandOne(item)
    def self.expandOne(item)
        if item["uxpayload-b4e4"] then
            return if !LucilleCore::askQuestionAnswerAsBoolean("'#{PolyFunctions::toString(item)}' has a payload, are you ok to lose it ? ")
        end

        if item["mikuType"] == "NxTask" then

            if NxTasks::isOrphan(item) then
                thread_description = LucilleCore::askQuestionAnswerAsString("thread description: ")
                puts "lines"
                sleep 0.5
                lines = Operations::interactivelyGetLines()
                priorityLevel = PriorityLevels::interactivelySelectOne()
                thread = NxThreads::issue(thread_description, priorityLevel)
                ListingService::ensure(thread)
                lines.reverse.each{|line|
                    task = NxTasks::descriptionToTask(line)
                    position = PolyFunctions::lastPositionInParent(thread) + 1
                    Parenting::insertEntry(thread["uuid"], task["uuid"], position)
                    ListingService::ensure(task)
                }
                Items::deleteItem(item["uuid"])
                return
            end

            parent = Parenting::parentOrNull(item["uuid"])
            position = Parenting::childPositionAtParentOrZero(parent["uuid"], item["uuid"])

            position1 = (lambda{|parent, position|
                positions = Parenting::childrenPositions(parent["uuid"])
                                .select{|pos| pos < position }
                return position - 1 if positions.empty?
                positions.max
 
            }).call(parent, position)
 
            position2 = (lambda{|parent, position|
                positions = Parenting::childrenPositions(parent["uuid"])
                                .select{|pos| pos > position }
                return position + 1 if positions.empty?
                positions.min
            }).call(parent, position)
 
            puts "position1: #{position1}"
            puts "position : #{position}"
            puts "position2: #{position2}"

            lines = Operations::interactivelyGetLines()
            return if lines.empty?

            size = lines.size

            lines.reverse.each_with_index{|line, i|
                ix = NxTasks::descriptionToTask(line)
                pox = position1 + (position2-position1)*(i+1).to_f/(size+1)
                Parenting::insertEntry(parent["uuid"], ix["uuid"], pox)
                ListingService::ensure(ix)
            }

            Items::deleteItem(item["uuid"])
            return
        end

        puts "I do not know how to replace a #{item["mikuType"]}"
        LucilleCore::pressEnterToContinue()
    end

    # Operations::relocateToNewParent(item)
    def self.relocateToNewParent(item)
        parent, position = Operations::decideParentAndPosition()
        Parenting::insertEntry(parent["uuid"], item["uuid"], position)
    end

    # Operations::relocateToNewThreadOrNothing(item)
    def self.relocateToNewThreadOrNothing(item)
        # At the moment parenting is only between a NxTask (child) and a NxThread (parent)
        return if item["mikuType"] != "NxTask"
        packet = Operations::architectParentAndPositionOrNull()
        return if packet.nil?
        Parenting::insertEntry(packet["parent"]["uuid"], item["uuid"], packet["position"])
    end
end
