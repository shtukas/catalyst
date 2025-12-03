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
        payload = UxPayloads::itemToPayloadOrNull(item)
        return payload.nil?
        UxPayloads::edit(payload)
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
                    FrontPage::additionalLines(item).each{|line|
                        puts " " * FrontPage::additionalLinesShift(item) + line
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
        puts "Bank::maintenance()"
        Bank::maintenance()
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
            Items::deleteObject(item["uuid"])
        end
    end

    # Operations::dive(item)
    def self.dive(item)
        NxSublines::dive(item)
    end
end
