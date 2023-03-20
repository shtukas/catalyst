
class Waves

    # ------------------------------------------------------------------
    # IO

    # Waves::items()
    def self.items()
        N3Objects::getMikuType("Wave")
    end

    # Waves::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # Waves::destroy(itemuuid)
    def self.destroy(itemuuid)
        N3Objects::destroy(itemuuid)
    end

    # --------------------------------------------------
    # Making

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

    # Waves::issueNewWaveInteractivelyOrNull(useCoreData: true)
    def self.issueNewWaveInteractivelyOrNull(useCoreData: true)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        nx46 = Waves::makeNx46InteractivelyOrNull()
        return nil if nx46.nil?
        uuid = SecureRandom.uuid
        coredataref = useCoreData ? CoreData::interactivelyMakeNewReferenceStringOrNull(uuid) : nil
        priority = LucilleCore::askQuestionAnswerAsBoolean("should display as priority ? ")
        item = {
            "uuid"             => uuid,
            "mikuType"         => "Wave",
            "unixtime"         => Time.new.to_i,
            "datetime"         => Time.new.utc.iso8601,
            "description"      => description,
            "nx46"             => nx46,
            "lastDoneDateTime" => "#{Time.new.strftime("%Y")}-01-01T00:00:00Z",
            "field11"          => coredataref,
            "priority"         => priority
        }
        N3Objects::commit(item)
        item
    end

    # -------------------------------------------------------------------------
    # Data (1)

    # Waves::toString(item)
    def self.toString(item)
        ago = "#{((Time.new.to_i - DateTime.parse(item["lastDoneDateTime"]).to_time.to_i).to_f/86400).round(2)} days ago"
        "(wave) #{item["description"]} (#{Waves::nx46ToString(item["nx46"])})#{CoreData::referenceStringToSuffixString(item["field11"])} (#{ago})#{item["priority"] ? " (priority)" : ""} 🌊"
    end

    # -------------------------------------------------------------------------
    # Data (2)
    # We do not display wave that are attached to a board (the board displays them)

    # Waves::listingItems(board)
    def self.listingItems(board)
        Waves::items()
            .select{|item| BoardsAndItems::belongsToThisBoard(item, board) }
            .sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }
            .select{|item|
                item["onlyOnDays"].nil? or item["onlyOnDays"].include?(CommonUtils::todayAsLowercaseEnglishWeekDayName())
            }
    end

    # Waves::listingItemsPriority(board)
    def self.listingItemsPriority(board)
        Waves::items()
            .select{|item| item["priority"] }
            .select{|item| BoardsAndItems::belongsToThisBoard(item, board) }
            .sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }
            .select{|item|
                item["onlyOnDays"].nil? or item["onlyOnDays"].include?(CommonUtils::todayAsLowercaseEnglishWeekDayName())
            }
    end

    # Waves::listingItemsLeisure(board)
    def self.listingItemsLeisure(board)
        Waves::items()
            .select{|item| !item["priority"] }
            .select{|item| BoardsAndItems::belongsToThisBoard(item, board) }
            .sort{|w1, w2| w1["lastDoneDateTime"] <=> w2["lastDoneDateTime"] }
            .select{|item|
                item["onlyOnDays"].nil? or item["onlyOnDays"].include?(CommonUtils::todayAsLowercaseEnglishWeekDayName())
            }
    end

    # -------------------------------------------------------------------------
    # Operations

    # Waves::performWaveNx46WaveDone(item)
    def self.performWaveNx46WaveDone(item)

        # Marking the item as being done 
        puts "done-ing: #{Waves::toString(item)}"
        item["lastDoneDateTime"] = Time.now.utc.iso8601
        item["parking"] = nil
        N3Objects::commit(item)

        # We control display using DoNotShowUntil
        unixtime = Waves::computeNextDisplayTimeForNx46(item["nx46"])
        puts "not shown until: #{Time.at(unixtime).to_s}"
        DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
    end

    # Waves::dive()
    def self.dive()
        loop {
            items = Waves::items().sort{|w1, w2| w1["description"] <=> w2["description"] }
            wave = LucilleCore::selectEntityFromListOfEntitiesOrNull("wave", items, lambda{|wave| wave["description"] })
            return if wave.nil?
            PolyActions::landing(wave)
        }
    end

    # Waves::access(item)
    def self.access(item)
        puts Waves::toString(item).green
        CoreData::access(item["field11"])
    end

    # Waves::landing(item)
    def self.landing(item)
        loop {
            puts Waves::toString(item)
            actions = ["update description", "update wave pattern", "perform done", "set days of the week", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            break if action.nil?
            if action == "update description" then
                item["description"] = CommonUtils::editTextSynchronously(item["description"])
                N3Objects::commit(item)
            end
            if action == "update wave pattern" then
                item["nx46"] = Waves::makeNx46InteractivelyOrNull()
                N3Objects::commit(item)
            end
            if action == "perform done" then
                Waves::performWaveNx46WaveDone(item)
                return
            end
            if action == "set days of the week" then
                days, _ = CommonUtils::interactivelySelectSomeDaysOfTheWeekLowercaseEnglish()
                item["onlyOnDays"] = days
                N3Objects::commit(item)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Waves::toString(item).green}' ? ", true) then
                    Waves::destroy(item["uuid"])
                    return
                end
            end
        }
    end
end
