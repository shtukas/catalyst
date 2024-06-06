
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

    # Waves::issueNewWaveInteractivelyOrNull(uuid)
    def self.issueNewWaveInteractivelyOrNull(uuid)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        nx46 = Waves::makeNx46InteractivelyOrNull()
        return nil if nx46.nil?
        Cubes1::itemInit(uuid, "Wave")
        interruption = LucilleCore::askQuestionAnswerAsBoolean("interruption ? ")
        Cubes1::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes1::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes1::setAttribute(uuid, "description", description)
        Cubes1::setAttribute(uuid, "nx46", nx46)
        Cubes1::setAttribute(uuid, "lastDoneDateTime", "#{Time.new.strftime("%Y")}-01-01T00:00:00Z")
        Cubes1::setAttribute(uuid, "interruption", interruption)
        Cubes1::setAttribute(uuid, "uxpayload-b4e4", UxPayload::makeNewOrNull())
        Cubes1::itemOrNull(uuid)
    end

    # -------------------------------------------------------------------------
    # Data (1)

    # Waves::toString(item)
    def self.toString(item)
        ago = "done: #{((Time.new.to_i - DateTime.parse(item["lastDoneDateTime"]).to_time.to_i).to_f/86400).round(2)} days ago"
        interruption = item["interruption"] ? " (interruption)" : ""
        "🌊 #{item["description"]} (#{Waves::nx46ToString(item["nx46"])}) (#{ago})#{interruption}"
    end

    # -------------------------------------------------------------------------
    # Data (2)

    # Waves::muiItems()
    def self.muiItems()
        isMuiItem = lambda { |item|
            b1 = Listing::listable(item)
            b2 = item["onlyOnDays"].nil? or item["onlyOnDays"].include?(CommonUtils::todayAsLowercaseEnglishWeekDayName())
            b1 and b2
        }
        Cubes1::mikuType("Wave")
            .select{|item| isMuiItem.call(item) }
            .sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }
    end

    # Waves::muiItemsInterruption()
    def self.muiItemsInterruption()
        Waves::muiItems()
            .select{|item| item["interruption"] }
    end

    # Waves::muiItemsNotInterruption()
    def self.muiItemsNotInterruption()
        Waves::muiItems()
            .select{|item| !item["interruption"] }
    end

    # -------------------------------------------------------------------------
    # Operations

    # Waves::performWaveDone(item)
    def self.performWaveDone(item)

        # Removing flight information
        Cubes1::setAttribute(item["uuid"], "flight-1742", nil)

        # Marking the item as being done 
        puts "done-ing: '#{Waves::toString(item).green}'"
        Cubes1::setAttribute(item["uuid"], "lastDoneUnixtime", Time.new.to_i)
        Cubes1::setAttribute(item["uuid"], "lastDoneDateTime", Time.now.utc.iso8601)

        # We control display using DoNotShowUntil
        unixtime = Waves::computeNextDisplayTimeForNx46(item["nx46"])
        puts "not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil1::setUnixtime(item["uuid"], unixtime)
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
                Cubes1::setAttribute(item["uuid"], "description", description)
            end
            if action == "update wave pattern" then
                nx46 = Waves::makeNx46InteractivelyOrNull()
                next if nx46.nil?
                Cubes1::setAttribute(item["uuid"], "nx46", nx46)
            end
            if action == "perform done" then
                Waves::performWaveDone(item)
                return
            end
            if action == "set priority" then
                Cubes1::setAttribute(item["uuid"], "interruption", LucilleCore::askQuestionAnswerAsBoolean("interruption ? "))
            end
            if action == "set days of the week" then
                days, _ = CommonUtils::interactivelySelectSomeDaysOfTheWeekLowercaseEnglish()
                Cubes1::setAttribute(item["uuid"], "onlyOnDays", days)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{Waves::toString(item).green}' ? ", true) then
                    Cubes1::destroy(item["uuid"])
                    return
                end
            end
        }
    end

    # Waves::program1()
    def self.program1()
        items = Cubes1::mikuType("Wave")
        i1, i2 = items.partition{|item| DoNotShowUntil1::isVisible(item) }
        i1.sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] } + i2.sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }
        items = i1 + i2
        Catalyst::program2(items)
    end
end
