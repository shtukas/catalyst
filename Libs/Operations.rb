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
        puts "Bank::maintenance()"
        Bank::maintenance()
        puts "Items::maintenance()"
        Items::maintenance()

        count = Items::mikuType("NxPolymorph")
                    .select{|item| item["behaviours"].any?{|behaviour| behaviour["btype"] == "task" } }
                    .size
        puts "task count: #{count}"
        if count < 50 then
            iced = Items::mikuType("NxIce")
            if iced.size == 0 then
                puts "We do not have any NxIce left, please remove [5b2268ae]"
                exit
            end
            iced
                .take(100)
                .each{|item|
                    next if !Dx8Units::attemptRepository()

                    behaviour = {
                        "btype" => "task",
                        "unixtime" => item["unixtime"] || Time.new.to_i
                    }
                    puts "moving #{item["uuid"]} from NxIce to polymorph task"
                    Items::setAttribute(item["uuid"], "behaviours", [behaviour])
                    Items::setAttribute(item["uuid"], "mikuType", "NxPolymorph")

                    if item["uxpayload-b4e4"] and item["uxpayload-b4e4"]["type"] == "Dx8Unit" then
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

                (lambda {
                    date = CommonUtils::tomorrow()
                    uuid = SecureRandom.uuid
                    Items::init(uuid)
                    behaviour = {
                        "btype" => "ondate",
                        "date" => date
                    }
                    payload = UxPayload::locationToPayload(uuid, location)
                    item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
                    puts JSON.pretty_generate(item)
                    Fsck::fsckOrError(item)
                }).call()

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

                (lambda {
                    date = CommonUtils::today()
                    uuid = SecureRandom.uuid
                    Items::init(uuid)
                    behaviour = {
                        "btype" => "ondate",
                        "date" => date
                    }
                    payload = UxPayload::locationToPayload(uuid, location)
                    item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
                    puts JSON.pretty_generate(item)
                    Fsck::fsckOrError(item)
                }).call()

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

                (lambda {
                    date = CommonUtils::tomorrow()
                    uuid = SecureRandom.uuid
                    Items::init(uuid)
                    behaviour = {
                        "btype" => "ondate",
                        "date" => date
                    }
                    payload = UxPayload::locationToPayload(uuid, location)
                    item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)
                    puts JSON.pretty_generate(item)
                    Fsck::fsckOrError(item)
                }).call()

                LucilleCore::removeFileSystemLocation(location)
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
        NxBalls::activeItems().each{|i|
            NxBalls::pause(i)
        }

        uuid = SecureRandom.uuid
        behaviour = {
            "btype" => "listing-position",
            "position" => NxPolymorphs::listingFirstPosition()
        }
        Items::init(uuid)
        payload = UxPayload::makeNewOrNull(uuid)
        item = NxPolymorphs::issueNew(uuid, description, [behaviour], payload)

        if LucilleCore::askQuestionAnswerAsBoolean("start ? ", true) then
            PolyActions::start(item)
        end
    end

    # Operations::program3ItemsWithGivenBehaviour(btype)
    def self.program3ItemsWithGivenBehaviour(btype)
        Operations::program3(lambda { Items::mikuType("NxPolymorph").select{|item| NxPolymorphs::itemHasBehaviour(item, btype) } })
    end

    # Operations::morning()
    def self.morning()
        items = FrontPage::itemsForListing()
                    .select{|item| item["behaviours"].first["btype"] != "task" }
        selected, unselected = items.partition{|item| item["behaviours"].first["btype"] == "DayCalendarItem" }
        cursor = ([Time.new.to_i] + selected.map{|item| item["behaviours"].first["start-unixtime"] + item["behaviours"].first["durationInMinutes"]*60 }).max
        loop {
            selected
                .sort_by{|item| item["behaviours"].first["start-unixtime"] }
                .each{|item|
                    puts PolyFunctions::toString(item)
                }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", unselected, lambda{ |item| PolyFunctions::toString(item) })
            break if item.nil?
            duration = LucilleCore::askQuestionAnswerAsString("duration for '#{PolyFunctions::toString(item)}' in minutes ? ").to_f
            behaviour = {
                "btype" => "DayCalendarItem",
                "start-unixtime" => cursor,
                "start-datetime" => Time.at(cursor).to_s,
                "durationInMinutes" => duration
            }
            item["behaviours"] = [behaviour] + item["behaviours"]
            Items::setAttribute(item["uuid"], "behaviours", item["behaviours"])
            selected << item
            unselected = unselected.select{|i| i["uuid"] != item["uuid"] }
            cursor = cursor + duration * 60
        }
    end

    # Operations::calm_first_unixtime_or_null()
    def self.calm_first_unixtime_or_null()
        return nil if NxBalls::all().size > 0
        items = FrontPage::itemsForListing()
                    .select{|item| item["behaviours"].first["btype"] != "task" }
                    .select{|item| item["behaviours"].first["btype"] == "DayCalendarItem" }
        return nil if items.nil?
        cursor = items.map{|item| item["behaviours"].first["start-unixtime"] }.min
        cursor
    end

    # Operations::monitor()
    def self.monitor()
        unixtime = Operations::calm_first_unixtime_or_null()
        return if unixtime.nil?
        return if (Time.new.to_i - unixtime).abs < 1200
        Operations::recalibrate()
    end

    # Operations::recalibrate()
    def self.recalibrate()
        puts "Operations::recalibrate()"
        if NxBalls::all().size > 0 then
            puts "You cannot recalibrate when there are active active"
            LucilleCore::pressEnterToContinue()
            return
        end
        items = FrontPage::itemsForListing()
                    .select{|item| item["behaviours"].first["btype"] != "task" }
                    .select{|item| item["behaviours"].first["btype"] == "DayCalendarItem" }
        cursor = Time.new.to_i
        items
            .sort_by{|item| item["behaviours"].first["start-unixtime"] }
            .each{|item|
                behaviour = item["behaviours"].first
                behaviour = {
                    "btype" => "DayCalendarItem",
                    "start-unixtime" => cursor,
                    "start-datetime" => Time.at(cursor).to_s,
                    "durationInMinutes" => behaviour["durationInMinutes"]
                }
                Items::setAttribute(item["uuid"], "behaviours", [behaviour] + item["behaviours"].drop(1))
                cursor = cursor + behaviour["durationInMinutes"]*60
            }
    end
end
