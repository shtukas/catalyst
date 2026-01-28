
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
        puts "listing position: #{ListingPosition::decideItemListingPositionOrNull(item)}"
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

    # Operations::morning()
    def self.morning()

        i1 = [
                NxBackups::listingItems(),
                NxOndates::listingItems(),
                Blades::mikuType("NxToday"),
                Waves::listingItems(),
                BufferIn::listingItems(),
                NxEngines::listingItems()
            ].map{|items|
                items = items.select{|item| DoNotShowUntil::isVisible(item) }
                if items.size > 0 then
                    LucilleCore::selectZeroOrMore("item", [], items, lambda {|item| PolyFunctions::toString(item) })[0]
                else
                    []
                end
            }.flatten

        i2 = Blades::mikuType("NxListing")
                .map{|listing|
                    puts PolyFunctions::toString(listing).green
                    items = NxListings::itemsInOrder(listing)
                        .select{|item| DoNotShowUntil::isVisible(item) }
                    if items.size > 0 then
                        LucilleCore::selectZeroOrMore("item", [], items, lambda {|item| PolyFunctions::toString(item) })[0]
                    else
                        []
                    end
                }
                .flatten

        items = i1+i2

        items.each{|item|
            Blades::setAttribute(item["uuid"], "active-67", true)
        }

        i1, i2 = LucilleCore::selectZeroOrMore("elements", [], items, lambda{|i| PolyFunctions::toString(i) })

        position = 0.351

        (i1+i2).each{|item|
            position = position + 0.001
            Blades::setAttribute(item["uuid"], "nx42", position)
        }
    end

    # Operations::move(item)
    def self.move(item)
        if item["mikuType"] == "NxTask" then
            ListingParenting::setMembership(item, NxListings::architectNx38())
            return
        end
        Transmute::transmuteTo(item, "NxTask")
    end
end

