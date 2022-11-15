
class Waves

    # --------------------------------------------------
    # IO

    # Waves::filepathForUUID(uuid)
    def self.filepathForUUID(uuid)
        "#{Config::pathToDataCenter()}/Wave/#{uuid}.Nx5"
    end

    # Waves::nx5Filepaths()
    def self.nx5Filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Wave")
            .select{|filepath| filepath[-4, 4] == ".Nx5" }
    end

    # Waves::items()
    def self.items()
        Waves::nx5Filepaths()
            .map{|filepath| Nx5Ext::readFileAsAttributesOfObject(filepath) }
    end

    # Waves::commitItem(item)
    def self.commitItem(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = Waves::filepathForUUID(item["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, item["uuid"])
        end
        item.each{|key, value|
            Nx5::emitEventToFile1(filepath, key, value)
        }
    end

    # Waves::commitAttribute1(uuid, attname, attvalue)
    def self.commitAttribute1(uuid, attname, attvalue)
        filepath = Waves::filepathForUUID(uuid)
        raise "(error: EDE283D3-0E7E-4D66-B055-160F43D127C5) uuid: '#{uuid}', attname: '#{attname}', attvalue: '#{attvalue}'" if !File.exists?(filepath)
        Nx5::emitEventToFile1(filepath, attname, attvalue)
    end

    # Waves::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = Waves::filepathForUUID(uuid)
        return nil if !File.exists?(filepath)
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # Waves::destroy(uuid)
    def self.destroy(uuid)
        filepath = Waves::filepathForUUID(uuid)
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # --------------------------------------------------
    # Making

    # Waves::interactivelySelectPriorityOrNull()
    def self.interactivelySelectPriorityOrNull()
        prioritys = ["time-critical", "time-aware", "non-important"]
        LucilleCore::selectEntityFromListOfEntitiesOrNull("priority:", prioritys)
    end

    # Waves::interactivelySelectPriority()
    def self.interactivelySelectPriority()
        loop {
            priority = Waves::interactivelySelectPriorityOrNull()
            return priority if priority
        }
    end

    # Waves::makeNx46InteractivelyOrNull()
    def self.makeNx46InteractivelyOrNull()

        scheduleTypes = ['sticky', 'repeat']
        scheduleType = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("schedule type: ", scheduleTypes)

        return nil if scheduleType.nil?

        if scheduleType=='sticky' then
            fromHour = LucilleCore::askQuestionAnswerAsString("From hour (integer): ").to_i
            return {
                "type"  => "sticky",
                "value" => fromHour
            }
        end

        if scheduleType=='repeat' then

            repeat_types = ['every-n-hours','every-n-days','every-this-day-of-the-week','every-this-day-of-the-month']
            type = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("repeat type: ", repeat_types, lambda{|entity| entity })

            return nil if type.nil?

            if type=='every-n-hours' then
                print "period (in hours): "
                value = STDIN.gets().strip.to_f
                return {
                    "type"  => type,
                    "value" => value
                }
            end
            if type=='every-n-days' then
                print "period (in days): "
                value = STDIN.gets().strip.to_f
                return {
                    "type"  => type,
                    "value" => value
                }
            end
            if type=='every-this-day-of-the-month' then
                print "day number (String, length 2): "
                value = STDIN.gets().strip
                return {
                    "type"  => type,
                    "value" => value
                }
            end
            if type=='every-this-day-of-the-week' then
                weekdays = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']
                value = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("weekday: ", weekdays, lambda{|entity| entity })
                return {
                    "type"  => type,
                    "value" => value
                }
            end
        end
        raise "e45c4622-4501-40e1-a44e-2948544df256"
    end

    # Waves::computeNextDisplayTimeForNx46(nx46: Nx46)
    def self.computeNextDisplayTimeForNx46(nx46)
        if nx46["type"] == 'sticky' then
            # unixtime1 is the time of the event happening today
            # It can still be ahead of us.
            unixtime1 = (CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) - 86400) + nx46["value"].to_i*3600
            if unixtime1 > Time.new.to_i then
                return unixtime1
            end
            # We return the event happening tomorrow
            return CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) + nx46["value"].to_i*3600
        end
        if nx46["type"] == 'every-n-hours' then
            return Time.new.to_i+3600 * nx46["value"].to_f
        end
        if nx46["type"] == 'every-n-days' then
            return Time.new.to_i+86400 * nx46["value"].to_f
        end
        if nx46["type"] == 'every-this-day-of-the-month' then
            cursor = Time.new.to_i + 86400
            while Time.at(cursor).strftime("%d") != nx46["value"] do
                cursor = cursor + 3600
            end
           return cursor
        end
        if nx46["type"] == 'every-this-day-of-the-week' then
            mapping = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
            cursor = Time.new.to_i + 86400
            while mapping[Time.at(cursor).wday] != nx46["value"] do
                cursor = cursor + 3600
            end
            return cursor
        end
        raise "(error: afe44910-57c2-4be5-8e1f-2c2fb80ae61a) nx46: #{JSON.pretty_generate(nx46)}"
    end

    # Waves::nx46ToString(item)
    def self.nx46ToString(item)
        if item["type"] == 'sticky' then
            return "sticky, from: #{item["value"]}"
        end
        "#{item["type"]}: #{item["value"]}"
    end

    # Waves::issueNewWaveInteractivelyOrNull()
    def self.issueNewWaveInteractivelyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        nx46 = Waves::makeNx46InteractivelyOrNull()
        return nil if nx46.nil?
        uuid = SecureRandom.uuid
        nx113 = Nx113Make::interactivelyMakeNx113OrNull(Waves::operatorForUUID(uuid))
        priority = Waves::interactivelySelectPriority()
        item = {
            "uuid"             => uuid,
            "mikuType"         => "Wave",
            "unixtime"         => Time.new.to_i,
            "datetime"         => Time.new.utc.iso8601,
            "description"      => description,
            "nx46"             => nx46,
            "priority"       => priority,
            "nx113"            => nx113,
            "lastDoneDateTime" => "#{Time.new.strftime("%Y")}-01-01T00:00:00Z"
        }
        Waves::commitItem(item)
        item
    end

    # -------------------------------------------------------------------------
    # Data

    # Waves::toString(item)
    def self.toString(item)
        lastDoneDateTime = item["lastDoneDateTime"]
        ago = "#{((Time.new.to_i - DateTime.parse(lastDoneDateTime).to_time.to_i).to_f/86400).round(2)} days ago"
        "(wave) #{item["description"]}#{Nx113Access::toStringOrNull(" ", item["nx113"], "")} (#{Waves::nx46ToString(item["nx46"])}) (#{ago}) 🌊 #{Cx22::contributionStringWithPrefixForCatalystItemOrEmptyString(item).green} [#{item["priority"]}]"
    end

    # -------------------------------------------------------------------------

    # Waves::operatorForUUID(uuid)
    def self.operatorForUUID(uuid)
        filepath = Waves::filepathForUUID(uuid)
        ElizabethNx5.new(filepath)
    end

    # Waves::operatorForItem(item)
    def self.operatorForItem(item)
        Waves::operatorForUUID(item["uuid"])
    end

    # Waves::performWaveNx46WaveDone(item)
    def self.performWaveNx46WaveDone(item)
        puts "done-ing: #{Waves::toString(item)}"
        Waves::commitAttribute1(item["uuid"], "lastDoneDateTime", Time.now.utc.iso8601)

        unixtime = Waves::computeNextDisplayTimeForNx46(item["nx46"])
        puts "not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(item["uuid"], unixtime)

        TxListingPointer::done(item["uuid"])
    end

    # Waves::dive()
    def self.dive()
        loop {
            waves = Waves::items()
            wave = LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", waves, lambda{|item| Waves::toString(item) })
            break if wave.nil?
            puts Waves::toString(wave)
            options = ["done", "landing"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            next if option.nil?
            if option == "done" then
                Waves::performWaveNx46WaveDone(wave)
                next
            end
            if option == "landing" then
                Waves::landing(wave)
                next
            end
        }
    end

    # Waves::access(item)
    def self.access(item)
        puts Waves::toString(item).green
        if item["nx113"] then
            Nx113Access::access(Waves::operatorForItem(item), item["nx113"])
        end
    end

    # Waves::edit(item) # item
    def self.edit(item)
        if item["nx113"].nil? then
            puts "This item doesn't have a Nx113 attached to it"
            status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
            if status then
                PolyActions::editDescription(item)
                return Waves::getOrNull(item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::editNx113Carrier(item)
        Waves::getOrNull(item["uuid"])
    end

    # Waves::landing(item)
    def self.landing(item)
        loop {

            return nil if item.nil?

            uuid = item["uuid"]
            item = Waves::getOrNull(uuid)
            return nil if item.nil?

            system("clear")

            puts PolyFunctions::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow

            puts ""
            puts "description | access | start | stop | edit | done | do not show until | nx46 (schedule) | only on days | nx113 | expose | destroy | nyx".yellow
            puts ""

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            # ordering: alphabetical

            if Interpreting::match("access", input) then
                PolyActions::access(item)
                next
            end

            if Interpreting::match("destroy", input) then
                PolyActions::destroyWithPrompt(item)
                return
            end

            if Interpreting::match("description", input) then
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                return if description == ""
                filepath = Waves::filepathForUUID(item["uuid"])
                Nx5Ext::setAttribute(filepath, "description", description)
                next
            end

            if Interpreting::match("done", input) then
                PolyActions::done(item)
                next
            end

            if Interpreting::match("do not show until", input) then
                datecode = LucilleCore::askQuestionAnswerAsString("datecode: ")
                return if datecode == ""
                unixtime = CommonUtils::codeToUnixtimeOrNull(datecode.gsub(" ", ""))
                return if unixtime.nil?
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end

            if Interpreting::match("edit", input) then
                item = PolyFunctions::edit(item)
                next
            end

            if Interpreting::match("expose", input) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("nx46", input) then
                nx46 = Waves::makeNx46InteractivelyOrNull()
                next if nx46.nil?
                Waves::commitAttribute1(item["uuid"], "nx46", nx46)
                next
            end

            if input == "only on days" then
                days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
                selected, _ = LucilleCore::selectZeroOrMore("days", [], days)
                Waves::commitAttribute1(item["uuid"], "onlyOnDays", selected)
                next
            end

            if Interpreting::match("nx113", input) then
                nx113 = Nx113Make::interactivelyMakeNx113OrNull(Waves::operatorForItem(item))
                return if nx113.nil?
                Waves::commitAttribute1(item["uuid"], "nx113", nx113)
                next
            end

            if Interpreting::match("nyx", input) then
                Nyx::program()
                next
            end
        }
    end
end
