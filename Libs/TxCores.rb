class TxCores

    # -----------------------------------------------
    # Build

    # TxCores::interactivelyMakeNewOrNull(ec = nil)
    def self.interactivelyMakeNewOrNull(ec = nil)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["booster","daily-hours", "weekly-hours", "blocking-until-done", "monitor", "content-driven"])
        return nil if type.nil?
        if type == "booster" then
            return TxCores::interactivelyMakeBoosterOrNull(ec)
        end
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
        if type == "content-driven" then
            return {
                "uuid"          => ec ? ec["uuid"] : SecureRandom.uuid,
                "mikuType"      => "TxCore",
                "type"          => "content-driven"
            }
        end
        raise "(error: 9ece0a71-f6bc-4b2d-ae27-3d4b5a0fac17)"
    end

    # TxCores::interactivelyMakeBoosterOrNull(ec = nil)
    def self.interactivelyMakeBoosterOrNull(ec = nil)
        hours = LucilleCore::askQuestionAnswerAsString("total hours (empty for abort): ")
        return nil if hours == ""
        hours = hours.to_f
        return nil if hours == 0
        expiry = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
        return {
            "uuid"        => ec ? ec["uuid"] : SecureRandom.uuid,
            "mikuType"    => "TxCore",
            "type"        => "booster",
            "startunixtime" => Time.new.to_i,
            "hours"       => hours,
            "endunixtime" => expiry
        }
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
            doneSinceLastSaturdayInSeconds = CommonUtils::datesSinceLastSaturday().reduce(0){|time, date| time + Bank::getValueAtDate(core["uuid"], date) }
            doneSinceLastSaturdayInHours = doneSinceLastSaturdayInSeconds.to_f/3600
            return doneSinceLastSaturdayInHours.to_f/core["hours"] if doneSinceLastSaturdayInHours >= core["hours"]
            dailyHours = core["hours"].to_f/7
            return Bank::recoveredAverageHoursPerDay(core["uuid"]).to_f/dailyHours
        end
        if core["type"] == "daily-hours" then
            dailyHours = core["hours"]
            hoursDoneToday = Bank::getValueAtDate(core["uuid"], CommonUtils::today()).to_f/3600
            x1 = hoursDoneToday.to_f/dailyHours
            x2 = Bank::recoveredAverageHoursPerDay(core["uuid"]).to_f/dailyHours
            return [0.8*x1 + 0.2*x2, x1].max
        end
        if core["type"] == "booster" then
            core["startunixtime"] = core["startunixtime"] || 1702659382
            core["endunixtime"] = core["endunixtime"] ? core["endunixtime"] : DateTime.parse(core["expiry"]).to_time.to_i
            deltaXToNow = [CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()), core["endunixtime"]].min - core["startunixtime"]
            deltaXTotal = core["endunixtime"] - core["startunixtime"]
            idealHours = core["hours"]*(deltaXToNow.to_f/deltaXTotal)
            hoursDone = Bank::getValue(core["uuid"]).to_f/3600
            return hoursDone.to_f/idealHours
        end
        if core["type"] == "blocking-until-done" then
            return 0
        end
        if core["type"] == "monitor" then
            return 0
        end
        if core["type"] == "content-driven" then
            raise "(error: 57df1e253f9c) we are no supposed to be able to call TxCores::coreDayCompletionRatio with #{core}" 
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
        if core["type"] == "booster" then
            if TxCores::coreDayCompletionRatio(core) < 1 then
                return "(#{"%6.2f" % (100*TxCores::coreDayCompletionRatio(core))} %; booster: #{"%5.2f" % core["hours"]} hs)".green
            else
                return "(expired booster            )".green
            end
        end
        if core["type"] == "weekly-hours" then
            return "(#{"%6.2f" % (100*TxCores::coreDayCompletionRatio(core))} %; weekly:  #{"%5.2f" % core["hours"]} hs)".green
        end
        if core["type"] == "daily-hours" then
            return "(#{"%6.2f" % (100*TxCores::coreDayCompletionRatio(core))} %; daily:   #{"%5.2f" % core["hours"]} hs)".green
        end
        if core["type"] == "content-driven" then
            return "(        ; content driven   )".green
        end
    end

    # TxCores::suffix2(item)
    def self.suffix2(item)
        return "" if item["engine-0020"].nil?
        " #{TxCores::suffix1(item["engine-0020"])}"
    end
end
