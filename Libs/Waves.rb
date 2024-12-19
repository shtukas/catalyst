
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

    # Waves::issueNewWaveInteractivelyOrNull(uuid)
    def self.issueNewWaveInteractivelyOrNull(uuid)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        nx46 = Waves::makeNx46InteractivelyOrNull()
        return nil if nx46.nil?
        Items::itemInit(uuid, "Wave")
        interruption = LucilleCore::askQuestionAnswerAsBoolean("interruption ? ")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "nx46", nx46)
        Items::setAttribute(uuid, "lastDoneUnixtime", 0)
        Items::setAttribute(uuid, "interruption", interruption)
        Items::setAttribute(uuid, "uxpayload-b4e4", UxPayload::makeNewOrNull(uuid))
        Items::itemOrNull(uuid)
    end

    # -------------------------------------------------------------------------
    # Data

    # Waves::nx46ToNextDisplayUnixtime(nx46: Nx46)
    def self.nx46ToNextDisplayUnixtime(nx46)
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

    # Waves::toString(item)
    def self.toString(item)
        ago = "done: #{((Time.new.to_i - item["lastDoneUnixtime"]).to_f/86400).round(2)} days ago"
        interruption = item["interruption"] ? " (interruption)" : ""
        "🌊 #{item["description"]} (#{Waves::nx46ToString(item["nx46"])}) (#{ago})#{interruption}"
    end

    # Waves::next_unixtime(item)
    def self.next_unixtime(item)
        Waves::nx46ToNextDisplayUnixtime(item["nx46"])
    end

    # -------------------------------------------------------------------------
    # Operations

    # Waves::perform_done(item)
    def self.perform_done(item)
        puts "done-ing: '#{Waves::toString(item).green}'"
        Items::setAttribute(item["uuid"], "lastDoneUnixtime", Time.new.to_i)
        unixtime = Waves::nx46ToNextDisplayUnixtime(item["nx46"])
        puts "not shown until: #{Time.at(unixtime).to_s}"

        NxGPS::reposition(item)
    end

    # Waves::program2(item)
    def self.program2(item)
        loop {
            puts Waves::toString(item)
            actions = ["update description", "update wave pattern", "perform done", "set priority", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            break if action.nil?
            if action == "update description" then
                description = CommonUtils::editTextSynchronously(item["description"])
                next if description == ""
                Items::setAttribute(item["uuid"], "description", description)
            end
            if action == "update wave pattern" then
                nx46 = Waves::makeNx46InteractivelyOrNull()
                next if nx46.nil?
                Items::setAttribute(item["uuid"], "nx46", nx46)
            end
            if action == "perform done" then
                Waves::perform_done(item)
                return
            end
            if action == "set priority" then
                Items::setAttribute(item["uuid"], "interruption", LucilleCore::askQuestionAnswerAsBoolean("interruption ? "))
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{Waves::toString(item).green}' ? ", true) then
                    Items::destroy(item["uuid"])
                    return
                end
            end
        }
    end

    # Waves::program1()
    def self.program1()
        items = Items::mikuType("Wave").sort_by{|wave| wave["gps-2119"] }
        Operations::program2(items)
    end
end
