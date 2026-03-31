class TimeCores

    # TimeCores::core_items_in_global_positioning_order(uuid)
    def self.core_items_in_global_positioning_order(uuid)
        Blades::items()
            .select{|item| item["timecore-57"] and item["timecore-57"]["uuid"] == uuid }
            .sort_by {|item| item["global-pos-07"] || 0 }
    end

    # TimeCores::get_time_core_or_null(uuid)
    def self.get_time_core_or_null(uuid)
        # the canonical one is carried by the first element
        items = TimeCores::core_items_in_global_positioning_order(uuid)
        return nil if items.empty?
        items.first["timecore-57"]
    end

    # TimeCores::get_timecore_description_or_null_cache_results(uuid)
    def self.get_timecore_description_or_null_cache_results(uuid)

        description = XCache::getOrNull("0084eebd-b644-4898-b0b6-d92590321092:#{uuid}")
        if description then
            if description == "fe38f834" then
                return nil
            end
            return description
        end

        timecore = TimeCores::get_time_core_or_null(uuid)
        if timecore then
            description = timecore["name"]
            XCache::set("0084eebd-b644-4898-b0b6-d92590321092:#{uuid}",description)
            return description
        end

        XCache::set("0084eebd-b644-4898-b0b6-d92590321092:#{uuid}","fe38f834")
        nil
    end

    # TimeCores::daily_ratio(uuid)
    def self.daily_ratio(uuid)
        # Here we are defaulting to zero if the core doesn't exists
        core = TimeCores::get_time_core_or_null(uuid)
        return 0 if core.nil?
        rt = BankDerivedData::recoveredAverageHoursPerDay(core["uuid"])
        daily_expectation = core["day-expectation-hours"] || 0
        rt.to_f/daily_expectation
    end

    # TimeCores::sort(uuid)
    def self.sort(uuid)
        items = TimeCores::core_items_in_global_positioning_order(uuid)
        selected = CommonUtils::selectZeroOrMore(items, lambda{|i| PolyFunctions::toString(i) })
        selected.reverse.each{|item|
            GlobalPositioning::insert_first(item)
        }
    end

    # TimeCores::time_cores()
    def self.time_cores()
        timecores = Blades::items()
            .select{|item| item["timecore-57"] }
            .map{|item| item["timecore-57"]["uuid"] }
            .uniq
            .map{|uuid| TimeCores::get_time_core_or_null(uuid) }
            .compact
    end

    # TimeCores::interactively_select_core_or_null()
    def self.interactively_select_core_or_null()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", TimeCores::time_cores(), lambda {|core| core["name"] })
    end

    # TimeCores::interactively_select_core()
    def self.interactively_select_core()
        loop {
            core = TimeCores::interactively_select_core_or_null()
            return core if core
        }
    end

    # TimeCores::architect_or_null()
    def self.architect_or_null()
        core = TimeCores::interactively_select_core_or_null()
        return core if core
        if LucilleCore::askQuestionAnswerAsBoolean("You did not select a core, would you like to make a new one ? ") then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return {
                "uuid" => SecureRandom.uuid,
                "name" => description
            }
        end
        nil
    end

    # TimeCores::suffix(item)
    def self.suffix(item)
        timecorestr = ""
        if item["timecore-57"] then
            timecorestr = " (timecore: #{item["timecore-57"]["name"]})".yellow
        end
        timecorestr
    end
end
