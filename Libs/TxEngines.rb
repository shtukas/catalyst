
class TxEngines

    # -----------------------------------------------
    # Build

    # TxEngines::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["orbital", "booster", "daily-work"])
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
        if type == "booster" then
            startUnixtime = Time.new.to_i
            endUnixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
            return nil if endUnixtime.nil?
            hours = LucilleCore::askQuestionAnswerAsString("period hours (empty for abort): ")
            return nil if hours == ""
            hours = hours.to_f
            return nil if hours == 0
            return {
                "uuid"          => SecureRandom.uuid,
                "mikuType"      => "TxEngine",
                "type"          => "booster",
                "startUnixtime" => startUnixtime,
                "endUnixtime"   => endUnixtime,
                "hours"         => hours
            }
        end
        if type == "daily-work" then
            return {
                "uuid"      => SecureRandom.uuid,
                "mikuType"  => "TxEngine",
                "type"      => "daily-work",
                "return-on" => CommonUtils::today()
            }
        end
        raise "(error: 9ece0a71-f6bc-4b2d-ae27-3d4b5a0fac17)"
    end

    # -----------------------------------------------
    # Data

    # TxEngines::dailyRelativeCompletionRatio(engine)
    def self.dailyRelativeCompletionRatio(engine)
        if engine["type"] == "orbital" then
            return [TxEngines::periodCompletionRatio(engine), Bank::recoveredAverageHoursPerDay(engine["uuid"]).to_f/(engine["hours"].to_f/6)].max
        end
        if engine["type"] == "booster" then

            periodInDays = (engine["endUnixtime"] - engine["startUnixtime"]).to_f/86400
            timeSpanSinceStartInDays = (CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) - engine["startUnixtime"]).to_f/86400
            timeRatio = [timeSpanSinceStartInDays.to_f/periodInDays, 1].min
            idealDoneTimeInSeconds = timeRatio*engine["hours"]*3600
            totalDoneRatioAgainstIdeal = Bank::getValue(engine["uuid"]).to_f/idealDoneTimeInSeconds

            if Time.new.to_i >= engine["endUnixtime"] and totalDoneRatioAgainstIdeal >= 1 then
                return 1
            end

            if Time.new.to_i > engine["endUnixtime"] then
                return 0
            end

            periodInDays = (engine["endUnixtime"] - engine["startUnixtime"]).to_f/86400
            dailyLoadInSeconds = (engine["hours"]*3600).to_f/periodInDays
            doneTodayInSeconds = Bank::getValueAtDate(engine["uuid"], CommonUtils::today())
            doneTodayRatio = doneTodayInSeconds.to_f/dailyLoadInSeconds

            return [totalDoneRatioAgainstIdeal, doneTodayInSeconds].min # strength
        end
        if engine["type"] == "daily-work" then
            if engine["return-on"] <= CommonUtils::today() then
                return 0
            else
                return 1
            end
        end
        raise "(error: 1cd26e69-4d2b-4cf7-9497-9bc715ea8f44)"
    end

    # TxEngines::periodCompletionRatio(engine)
    def self.periodCompletionRatio(engine)
        if engine["type"] == "orbital" then
            return Bank::getValue(engine["capsule"]).to_f/(engine["hours"]*3600)
        end
        raise "(error: 7e31bade-9db7-4e65-9da4-ccef7f70baa3)"
    end

    # TxEngines::toStringSuffix(engine)
    def self.toStringSuffix(engine)
        if engine["type"] == "orbital" then
            strings = []

            strings << " (daily: #{"%6.2f" % (100*TxEngines::dailyRelativeCompletionRatio(engine))} %, period: #{"#{"%6.2f" % (100*TxEngines::periodCompletionRatio(engine))}%".green} of #{"%5.2f" % engine["hours"]} hours"

            hasReachedObjective = Bank::getValue(engine["capsule"]) >= engine["hours"]*3600
            timeSinceResetInDays = (Time.new.to_i - engine["lastResetTime"]).to_f/86400
            itHassBeenAWeek = timeSinceResetInDays >= 7

            if hasReachedObjective and itHassBeenAWeek then
                strings << ", awaiting data management)"
            end

            if hasReachedObjective and !itHassBeenAWeek then
                strings << ", objective met, #{(7 - timeSinceResetInDays).round(2)} days before reset)"
            end

            if !hasReachedObjective and !itHassBeenAWeek then
                strings << ", #{(engine["hours"] - Bank::getValue(engine["capsule"]).to_f/3600).round(2)} hours to go, #{(7 - timeSinceResetInDays).round(2)} days left in period)"
            end

            if !hasReachedObjective and itHassBeenAWeek then
                strings << ", late by #{(timeSinceResetInDays-7).round(2)} days)"
            end

            strings << ""
            return strings.join()
        end
        raise "(error: 3127be8e-cf0f-466d-a29c-3b35a3aab4bb)"
    end

    # TxEngines::shouldShowInListing(item)
    def self.shouldShowInListing(item)
        return true if item["engine-0916"].nil?
        engine = item["engine-0916"]
        if engine["type"] == "orbital" then
            return true
        end
        if engine["type"] == "booster" then
            return true
        end
        if engine["type"] == "daily-work" then
            return engine["return-on"] <= CommonUtils::today()
        end
        raise "(error: 808b0460-793b-40cb-b919-27b813c2c37c)"
    end

    # TxEngines::listingItems()
    def self.listingItems()
        Catalyst::catalystItems()
            .select{|item| item["engine-0916"] }
            .reject{|item| item["mikuType"] == "TxCore" }
            .select{|item| TxEngines::shouldShowInListing(item) }
            .select{|item| TxEngines::dailyRelativeCompletionRatio(item["engine-0916"]) < 1 }
            .sort_by{|item| TxEngines::dailyRelativeCompletionRatio(item["engine-0916"]) }
    end

    # TxEngines::listingItems2()
    def self.listingItems2()
        Catalyst::catalystItems()
            .select{|item| item["engine-0916"] }
            .reject{|item| item["mikuType"] == "TxCore" }
            .select{|item| TxEngines::shouldShowInListing(item) }
            .sort_by{|item| TxEngines::dailyRelativeCompletionRatio(item["engine-0916"]) }
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
        if engine["type"] == "booster" then
            return nil
        end
        if engine["type"] == "daily-work" then
            return nil
        end
        raise "(error: 808b0460-793b-40cb-b919-27b813c2c37c)"
    end

    # TxEngines::prefix2(item)
    def self.prefix2(item)
        return "" if item["engine-0916"].nil?
        engine = item["engine-0916"]
        if engine["type"] == "orbital" then
            return "(orbital: #{"%5.2f" % (100*TxEngines::dailyRelativeCompletionRatio(engine))} % of #{"%4.2f" % (engine["hours"].to_f/6)} hours) ".green
        end
        if engine["type"] == "booster" then
            if Time.new.to_i > engine["endUnixtime"] then
                return "(booster: expired) ".green
            end
            periodInDays = (engine["endUnixtime"] - engine["startUnixtime"]).to_f/86400
            dailyLoadInHours = engine["hours"].to_f/periodInDays
            return "(booster: #{"%5.2f" % (100*TxEngines::dailyRelativeCompletionRatio(engine))} % of #{"%4.2f" % dailyLoadInHours} hours) ".green
        end
        if engine["type"] == "daily-work" then
            return "(daily) (do, tw | destroy) ".green
        end
        raise "(error: 4b7edb83-5a10-4907-b88f-53a5e7777154)"
    end

    # TxEngines::maintenance0924()
    def self.maintenance0924()
        Catalyst::catalystItems().each{|item|
            next if item["mikuType"] == "NxThePhantomMenace"
            next if item["engine-0916"].nil?
            e2 = TxEngines::maintenance1(item["engine-0916"], PolyFunctions::toString(item))
            next if e2.nil?
            Updates::itemAttributeUpdate(item["uuid"], "engine-0916", e2)
        }
    end
end
