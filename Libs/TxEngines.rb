
class TxEngines

    # -----------------------------------------------
    # Build

    # TxEngines::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["orbital", "daily-contribution-until-done", "weekly-contribution-until-done", "invisible"])
        return nil if type.nil?
        if type == "orbital" then
            hours = LucilleCore::askQuestionAnswerAsString("weekly hours (empty for abort): ")
            return nil if hours == ""
            hours = hours.to_f
            return nil if hours == 0
            return {
                "uuid"          => SecureRandom.uuid,
                "mikuType"      => "TxEngine",
                "type"          => "orbital",
                "hours"         => hours,
                "lastResetTime" => Time.new.to_i,
                "capsule"       => SecureRandom.hex
            }
        end
        if type == "daily-contribution-until-done" then
            hours = LucilleCore::askQuestionAnswerAsString("daily hours (empty for abort): ")
            return nil if hours == ""
            hours = hours.to_f
            return nil if hours == 0
            return {
                "uuid"          => SecureRandom.uuid,
                "mikuType"      => "TxEngine",
                "type"          => "daily-contribution-until-done",
                "hours"         => hours
            }
        end
        if type == "weekly-contribution-until-done" then
            hours = LucilleCore::askQuestionAnswerAsString("weekly hours (empty for abort): ")
            return nil if hours == ""
            hours = hours.to_f
            return nil if hours == 0
            return {
                "uuid"          => SecureRandom.uuid,
                "mikuType"      => "TxEngine",
                "type"          => "weekly-contribution-until-done",
                "startunixtime" => Time.new.to_f,
                "hours"         => hours
            }
        end
        if type == "invisible" then
            return {
                "uuid"      => SecureRandom.uuid,
                "mikuType"  => "TxEngine",
                "type"      => "invisible"
            }
        end
        raise "(error: 9ece0a71-f6bc-4b2d-ae27-3d4b5a0fac17)"
    end

    # -----------------------------------------------
    # Data

    # TxEngines::dayCompletionRatio(engine)
    def self.dayCompletionRatio(engine)
        if engine["type"] == "orbital" then
            if Bank::getValue(engine["capsule"]) >= 3600*engine["hours"] then
                return Bank::getValue(engine["capsule"]).to_f/(3600*engine["hours"])
            end
            return Bank::recoveredAverageHoursPerDay(engine["uuid"]).to_f/(engine["hours"].to_f/6)
        end
        if engine["type"] == "invisible" then
            return 1
        end
        if engine["type"] == "daily-contribution-until-done" then
            return Bank::getValueAtDate(engine["uuid"], CommonUtils::today()).to_f/(engine["hours"]*3600)
        end
        if engine["type"] == "weekly-contribution-until-done" then
            cursorUnixtime = CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone())
            timeSinceStartInWeeks = (cursorUnixtime - engine["startunixtime"]).to_f/(86400*7)
            idealBankInSeconds = timeSinceStartInWeeks * engine["hours"] * 3600
            return Bank::getValue(engine["uuid"]).to_f/idealBankInSeconds
        end
        raise "(error: 1cd26e69-4d2b-4cf7-9497-9bc715ea8f44): engine: #{engine}"
    end

    # TxEngines::suffix(item)
    def self.suffix(item)
        return "" if item["engine-0916"].nil?
        engine = item["engine-0916"]
        if engine["type"] == "orbital" then
            return " (#{"%6.2f" % (100*TxEngines::dayCompletionRatio(engine))} % of #{"%5.2f" % (engine["hours"].to_f/6)} hours)".green
        end
        if engine["type"] == "invisible" then
            return ""
        end
        if engine["type"] == "daily-contribution-until-done" then
            return " (#{"%6.2f" % (100*TxEngines::dayCompletionRatio(engine))} % of #{"%5.2f" % engine["hours"]} hours)".green
        end
        if engine["type"] == "weekly-contribution-until-done" then
            return " (#{"%6.2f" % (100*TxEngines::dayCompletionRatio(engine))} % of #{"%5.2f" % (engine["hours"].to_f/6)} hours)".green
        end
        raise "(error: 4b7edb83-5a10-4907-b88f-53a5e7777154) engine: #{engine}"
    end

    # TxEngines::shouldShowInListing(item)
    def self.shouldShowInListing(item)
        return true if item["engine-0916"].nil?
        if item["engine-0916"]["type"] == "invisible" then
            return false
        end
        true
    end

    # TxEngines::listingItems()
    def self.listingItems()
        DataCenter::catalystItems()
            .select{|item| item["engine-0916"] }
            .select{|item| TxEngines::shouldShowInListing(item) }
    end

    # -----------------------------------------------
    # Ops

    # TxEngines::maintenance1(engine, description) # engine or null
    def self.maintenance1(engine, description)
        if engine["type"] == "orbital" then
            return nil if Bank::getValue(engine["capsule"]).to_f/3600 < engine["hours"]
            return nil if (Time.new.to_i - engine["lastResetTime"]) < 86400*7
            puts "> I am about to reset engine for #{description}"
            LucilleCore::pressEnterToContinue()
            Bank::put(engine["capsule"], -engine["hours"]*3600)
            if !LucilleCore::askQuestionAnswerAsBoolean("> continue with #{engine["hours"]} hours ? ") then
                hours = LucilleCore::askQuestionAnswerAsString("specify period load in hours (empty for the current value): ")
                if hours.size > 0 then
                    engine["hours"] = hours.to_f
                end
            end
            engine["lastResetTime"] = Time.new.to_i
            return engine
        end
        if engine["type"] == "invisible" then
            return nil
        end
        if engine["type"] == "daily-contribution-until-done" then
            return nil
        end
        if engine["type"] == "weekly-contribution-until-done" then
            return nil
        end
        raise "(error: 808b0460-793b-40cb-b919-27b813c2c37c)"
    end

    # TxEngines::maintenance0924()
    def self.maintenance0924()
        DataCenter::catalystItems().each{|item|
            next if item["engine-0916"].nil?
            e2 = TxEngines::maintenance1(item["engine-0916"], PolyFunctions::toString(item))
            next if e2.nil?
            DataCenter::setAttribute(item["uuid"], "engine-0916", e2)
        }
    end
end
