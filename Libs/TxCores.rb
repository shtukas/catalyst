class TxCores

    # -----------------------------------------------
    # Build

    # TxCores::interactivelyMakeNewOrNull(ec = nil)
    def self.interactivelyMakeNewOrNull(ec = nil)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["daily-hours", "weekly-hours", "monitor"])
        return nil if type.nil?
        if type == "daily-hours" then
            hours = LucilleCore::askQuestionAnswerAsString("daily hours (empty for abort): ")
            return nil if hours == ""
            hours = hours.to_f
            return nil if hours == 0
            return {
                "uuid"          => ec ? ec["uuid"] : SecureRandom.uuid,
                "mikuType"      => "TxCore",
                "type"          => "daily-hours",
                "hours"         => hours,
            }
        end
        if type == "weekly-hours" then
            hours = LucilleCore::askQuestionAnswerAsString("weekly hours (empty for abort): ")
            return nil if hours == ""
            hours = hours.to_f
            return nil if hours == 0
            return {
                "uuid"          => ec ? ec["uuid"] : SecureRandom.uuid,
                "mikuType"      => "TxCore",
                "type"          => "weekly-hours",
                "hours"         => hours
            }
        end
        if type == "blocking-until-done" then
            return {
                "uuid"          => ec ? ec["uuid"] : SecureRandom.uuid,
                "mikuType"      => "TxCore",
                "type"          => "blocking-until-done"
            }
        end
        if type == "monitor" then
            return {
                "uuid"          => ec ? ec["uuid"] : SecureRandom.uuid,
                "mikuType"      => "TxCore",
                "type"          => "monitor"
            }
        end
        raise "(error: 9ece0a71-f6bc-4b2d-ae27-3d4b5a0fac17)"
    end

    # TxCores::interactivelyMakeNew()
    def self.interactivelyMakeNew()
        core = TxCores::interactivelyMakeNewOrNull()
        return core if core
        TxCores::interactivelyMakeNew()
    end

    # -----------------------------------------------
    # Data

    # TxCores::coreDayCompletionRatio(core)
    def self.coreDayCompletionRatio(core)
        return 0 if core.nil?
        if core["type"] == "weekly-hours" then
            doneSinceLastSaturdayInSeconds = CommonUtils::datesSinceLastSaturday().reduce(0){|time, date| time + Bank2::getValueAtDate(core["uuid"], date) }
            doneSinceLastSaturdayInHours = doneSinceLastSaturdayInSeconds.to_f/3600
            return doneSinceLastSaturdayInHours.to_f/core["hours"] if doneSinceLastSaturdayInHours >= core["hours"]
            dailyHours = core["hours"].to_f/7
            return Bank2::recoveredAverageHoursPerDay(core["uuid"]).to_f/dailyHours
        end
        if core["type"] == "daily-hours" then
            dailyHours = core["hours"]
            hoursDoneToday = Bank2::getValueAtDate(core["uuid"], CommonUtils::today()).to_f/3600
            x1 = hoursDoneToday.to_f/dailyHours
            x2 = Bank2::recoveredAverageHoursPerDay(core["uuid"]).to_f/dailyHours
            return [0.8*x1 + 0.2*x2, x1].max
        end
        if core["type"] == "blocking-until-done" then
            return 0
        end
        if core["type"] == "monitor" then
            return 0
        end
        if core["type"] == "special-circumstances-bottom-task-1939" then
            return 1
        end
        raise "(error: 1cd26e69-4d2b-4cf7-9497-9bc715ea8f44): core: #{core}"
    end

    # TxCores::suffix1(core, context = nil)
    def self.suffix1(core, context = nil)
        if context == "listing" then
            return ""
        end
        if core["type"] == "blocking-until-done" then
            return "(  0.00 %; blocking til done)".green
        end
        if core["type"] == "monitor" then
            return "( monitor                   )".green
        end
        if core["type"] == "weekly-hours" then
            return "(#{"%6.2f" % (100*TxCores::coreDayCompletionRatio(core))} %; weekly:  #{"%5.2f" % core["hours"]} hs)".green
        end
        if core["type"] == "daily-hours" then
            return "(#{"%6.2f" % (100*TxCores::coreDayCompletionRatio(core))} %; daily:   #{"%5.2f" % core["hours"]} hs)".green
        end
        if core["type"] == "special-circumstances-bottom-task-1939" then
            return ""
        end
    end

    # TxCores::suffix2(item)
    def self.suffix2(item)
        return "" if item["engine-0020"].nil?
        if item["engine-0020"]["type"] == "special-circumstances-bottom-task-1939" then
            return ""
        end
        if item["engine-0020"]["type"] == "blocking-until-done" then
            puts "item: #{PolyFunctions::toString(item)}"
            puts "core of type 'blocking-until-done' is deprecated, please make another one"
            core = TxCores::interactivelyMakeNew()
            Cubes2::setAttribute(item["uuid"], "engine-0020", core)
            item["engine-0020"] = core
        end
        " #{TxCores::suffix1(item["engine-0020"])}"
    end
end
