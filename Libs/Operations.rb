
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
        puts "listing position: #{JSON.generate(ListingPosition::listingBucketAndPositionOrNull(item))}"
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

    # Operations::move(item)
    def self.move(item)
        if item["mikuType"] == "NxTask" then
            ListingParenting::setMembership(item, NxListings::architectNx38())
            return
        end
        Transmute::transmuteTo(item, "NxTask")
    end

    # Operations::replan()
    def self.replan()
        nx1s = FrontPage::itemsAndBucketPositionsForListing()
        #nx1: {
        #    "item"            : item,
        #    "bucket&position" : data
        #}

        nx1s = nx1s.each{|nx1|
            item = nx1["item"]
            bucket, position = nx1["bucket&position"]

            if position < 4.00 then # the end of today
                if item["duration-38"].nil? then
                    duration = LucilleCore::askQuestionAnswerAsString("#{PolyFunctions::toString(item).green}: duration in minutes : ").to_f
                    item["duration-38"] = duration
                    Blades::setAttribute(item["uuid"], "duration-38", duration)
                end
            end

            nx1["item"] = item
            nx1
        }

        time_cursor = Time.new.to_f

        nx1s.each{|nx1|
            item = nx1["item"]
            bucket, position = nx1["bucket&position"]
            next if position >= 4.00

            item = nx1["item"]
            duration = item["duration-38"]
            end_unixtime = time_cursor + duration * 60
            nx2 = {
                "start-unixtime" => time_cursor,
                "start-datetime" => Time.at(time_cursor).to_s,
                "duration"       => duration,
                "end-unixtime"   => end_unixtime,
                "end-datetime"   => Time.at(end_unixtime).to_s,
            }
            XCache::set("nx2:295e252e-9732-4c9d-9020-12374a2c334c:#{item["uuid"]}", JSON.generate(nx2))
            time_cursor = end_unixtime
        }
    end

    # Operations::planningStatus(nx1s)
    def self.planningStatus(nx1s)
        nx1s = FrontPage::itemsAndBucketPositionsForListing()
        #nx1: {
        #    "item"            : item,
        #    "bucket&position" : data
        #}

        end_unixtime = nil

        nx1s.each{|nx1|
            item = nx1["item"]
            nx2 = XCache::getOrNull("nx2:295e252e-9732-4c9d-9020-12374a2c334c:#{item["uuid"]}")
            next if nx2.nil?
            nx2 = JSON.parse(nx2)
            if Time.new.to_i > nx2["end-unixtime"] then
                return "warning: #{PolyFunctions::toString(item)} is overflowing"
            end
            end_unixtime = nx2["end-unixtime"]
        }

        if end_unixtime and DateTime.parse("#{CommonUtils::today()} 23:00:00").to_time.to_i < end_unixtime then
            return "warning: you are finishing after 23:00 (#{Time.at(end_unixtime).to_s})"
        end

        nil
    end
end

