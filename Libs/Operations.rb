
class Operations

    # Operations::editItemJson(item)
    def self.editItemJson(item)
        # This function edit the payload, if there is now
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.each{|k, v|
            Blades::setAttribute(item["uuid"], k, v)
        }
    end

    # Operations::editItem(item)
    def self.editItem(item)
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["edit description", "edit payload", "edit json"])
        return if option.nil?
        if option == "edit description" then
            PolyActions::editDescription(item)
        end
        if option == "edit payload" then
            UxPayloads::editItemPayload(item)
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

    # Operations::globalMaintenanceSync()
    def self.globalMaintenanceSync()
        puts "Running global maintenance sync, every half a day, on primary instance".yellow
    end

    # Operations::globalMaintenanceASync()
    def self.globalMaintenanceASync()
        Bank::maintenance()
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
        DoNotShowUntil::doNotShowUntil(item, unixtime)
    end

    # Operations::expose(item)
    def self.expose(item)
        puts JSON.pretty_generate(item)
        puts ""
        puts "front page line: #{FrontPage::toString2(ItemStore.new(), item)}"
        LucilleCore::pressEnterToContinue()
    end

    # Operations::postponeToTomorrowOrDestroy(item)
    def self.postponeToTomorrowOrDestroy(item)
        puts PolyFunctions::toString(item).green
        options = ["postpone to tomorrow (default)", "destroy"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        if option.nil? or option == "postpone to tomorrow (default)" then
            DoNotShowUntil::doNotShowUntil(item, CommonUtils::unixtimeAtTomorrowMorningAtLocalTimezone())
        end
        if option == "destroy" then
            Blades::deleteItem(item["uuid"])
        end
    end

    # Operations::xstream()
    def self.xstream()
        removeLastElement = lambda{|stack|
            stack.reverse.drop(1).reverse
        }
        processItem = lambda {|stack|
            loop {
                puts ""
                cursor = nil
                stack.each{|i|
                    puts FrontPage::toString2(nil, i).strip
                    cursor = i
                }
                input = LucilleCore::askQuestionAnswerAsString("start | access | run (start+access) | ... | stop | done | +(datecode) | clique | sort | stack | unstack: ")
                if input == "start" then
                    PolyActions::start(cursor)
                    next
                end
                if input == "stop" then
                    PolyActions::stop(cursor)
                    return ["stack", removeLastElement.call(stack)]
                end
                if input == "done" then
                    PolyActions::done(cursor)
                    return ["stack", removeLastElement.call(stack)]
                end
                if input == "access" then
                    PolyActions::access(cursor)
                    next
                end
                if input == "..." then
                    puts "starting"
                    PolyActions::start(cursor)
                    puts "accessing"
                    PolyActions::access(cursor)
                    PolyActions::done(cursor)
                    return ["stack", removeLastElement.call(stack)]
                end
                if input == "run" then
                    puts "starting"
                    PolyActions::start(cursor)
                    puts "accessing"
                    PolyActions::access(cursor)
                    next
                end
                if input == "sort" then
                    s1, s2 = LucilleCore::selectZeroOrMore("element", [], stack, lambda{|i| FrontPage::toString2(nil, i) })
                    stack = s1 + s2
                    next
                end
                if input == "stack" then
                    return ["stack", stack]
                end
                if input == "unstack" then
                    stack = removeLastElement.call(stack)
                    next
                end
                if input == "exit" then
                    return ["exit"]
                end
                if input == "clique" then
                    if cursor["mikuType"] == "NxTask" then
                        nx38s = cursor["clique8"] # Array[Nx38]
                        nx38 = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", memberships, lambda{|nx38| Cliques::toString2(nx38["uuid"]) })
                        Cliques::diveClique(nx38["uuid"])
                    end
                    next
                end
                if input.start_with?("+") and (unixtime = CommonUtils::codeToUnixtimeOrNull(input.gsub(" ", ""))) then
                    PolyActions::stop(cursor)
                    ListingPosition::delist(cursor)
                    "dot not show until: #{Time.at(unixtime).to_s}".yellow
                    DoNotShowUntil::doNotShowUntil(cursor, unixtime)
                    return ["stack", removeLastElement.call(stack)]
                end
            }
            raise "d576acb8: error incorrect path"
        }
        getNextItem = lambda {|stack|
            FrontPage::itemsForListing().each{|i1|
                Prefix::prefix(i1).each{|i2|
                    next if BankDerivedData::recoveredAverageHoursPerDay(i2["uuid"]) > 1
                    next if stack.map{|i| i["uuid"] }.include?(i2["uuid"])
                    return stack + [i2]
                }
            }
        }
        stack = NxBalls::activePackets().map{|packet| packet["item"] }
        loop {
            answer = processItem.call(getNextItem.call(stack))
            if answer[0] == "exit" then
                return
            end
            if answer[0] == "stack" then
                stack = answer[1]
            end
        }
    end
end

