
class Waves

    # --------------------------------------------------
    # Making

    # Waves::makeNx46InteractivelyOrNull()
    def self.makeNx46InteractivelyOrNull()

        scheduleTypes = ['sticky', 'repeat']
        scheduleType = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("schedule type: ", scheduleTypes)

        return nil if scheduleType.nil?

        if scheduleType == 'sticky' then
            fromHour = LucilleCore::askQuestionAnswerAsString("From hour (integer): ").to_i
            return {
                "type"  => "sticky",
                "value" => fromHour
            }
        end

        if scheduleType == 'repeat' then

            repeat_types = ['every-n-hours','every-n-days','every-this-day-of-the-week','every-this-day-of-the-month']
            type = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("repeat type: ", repeat_types, lambda{|entity| entity })

            return nil if type.nil?

            if type == 'every-n-hours' then
                print "period (in hours): "
                value = STDIN.gets().strip.to_f
                return {
                    "type"  => type,
                    "value" => value
                }
            end
            if type == 'every-n-days' then
                print "period (in days): "
                value = STDIN.gets().strip.to_f
                return {
                    "type"  => type,
                    "value" => value
                }
            end
            if type == 'every-this-day-of-the-month' then
                print "day number (String, length 2): "
                value = STDIN.gets().strip
                return {
                    "type"  => type,
                    "value" => value
                }
            end
            if type == 'every-this-day-of-the-week' then
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
            while Time.at(cursor).strftime("%d") != nx46["value"].rjust(2, "0") do
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
        Events::publishItemInit("Wave", uuid)
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        interruption = LucilleCore::askQuestionAnswerAsBoolean("interruption ? ")
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "nx46", nx46)
        Events::publishItemAttributeUpdate(uuid, "lastDoneDateTime", "#{Time.new.strftime("%Y")}-01-01T00:00:00Z")
        Events::publishItemAttributeUpdate(uuid, "field11", coredataref)
        Events::publishItemAttributeUpdate(uuid, "interruption", interruption)
        Catalyst::itemOrNull(uuid)
    end

    # -------------------------------------------------------------------------
    # Data (1)

    # Waves::toString(item)
    def self.toString(item)
        ago = "done: #{((Time.new.to_i - DateTime.parse(item["lastDoneDateTime"]).to_time.to_i).to_f/86400).round(2)} days ago"
        interruption = item["interruption"] ? " (interruption)" : ""
        "♻️  #{item["description"]} (#{Waves::nx46ToString(item["nx46"])})#{CoreDataRefStrings::itemToSuffixString(item)} (#{ago})#{TxCores::suffix(item)}#{interruption}"
    end

    # -------------------------------------------------------------------------
    # Data (2)

    # Waves::listingItems()
    def self.listingItems()
        Catalyst::mikuType("Wave")
            .select{|item| Listing::listable(item) }
            .sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }
            .select{|item|
                item["onlyOnDays"].nil? or item["onlyOnDays"].include?(CommonUtils::todayAsLowercaseEnglishWeekDayName())
            }
    end

    # -------------------------------------------------------------------------
    # Operations

    # Waves::performWaveDone(item)
    def self.performWaveDone(item)

        # Marking the item as being done 
        puts "done-ing: '#{Waves::toString(item).green}'"
        Events::publishItemAttributeUpdate(item["uuid"], "lastDoneUnixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(item["uuid"], "lastDoneDateTime", Time.now.utc.iso8601)

        # We control display using DoNotShowUntil
        unixtime = Waves::computeNextDisplayTimeForNx46(item["nx46"])
        puts "not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(item, unixtime)
    end

    # Waves::access(item)
    def self.access(item)
        puts Waves::toString(item).green
        CoreDataRefStrings::access(item["uuid"], item["field11"])
    end

    # Waves::program2(item)
    def self.program2(item)
        loop {
            puts Waves::toString(item)
            actions = ["update description", "update wave pattern", "perform done", "set priority", "set days of the week", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            break if action.nil?
            if action == "update description" then
                description = CommonUtils::editTextSynchronously(item["description"])
                next if description == ""
                Events::publishItemAttributeUpdate(item["uuid"], "description", description)
            end
            if action == "update wave pattern" then
                nx46 = Waves::makeNx46InteractivelyOrNull()
                next if nx46.nil?
                Events::publishItemAttributeUpdate(item["uuid"], "nx46", nx46)
            end
            if action == "perform done" then
                Waves::performWaveDone(item)
                return
            end
            if action == "set priority" then
                Events::publishItemAttributeUpdate(item["uuid"], "interruption", LucilleCore::askQuestionAnswerAsBoolean("interruption ? "))
            end
            if action == "set days of the week" then
                days, _ = CommonUtils::interactivelySelectSomeDaysOfTheWeekLowercaseEnglish()
                Events::publishItemAttributeUpdate(item["uuid"], "onlyOnDays", days)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{Waves::toString(item).green}' ? ", true) then
                    Catalyst::destroy(item["uuid"])
                    return
                end
            end
        }
    end

    # Waves::program1()
    def self.program1()
        loop {
            items = Catalyst::mikuType("Wave").sort{|w1, w2| w1["description"] <=> w2["description"] }
            wave = LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", items, lambda{|wave| wave["description"] })
            return if wave.nil?
            Waves::program2(wave)
        }
    end

    # Waves::fsck()
    def self.fsck()
        Catalyst::mikuType("Wave").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
