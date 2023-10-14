
class TxEngines

    # -----------------------------------------------
    # Build

    # TxEngines::make(hours)
    def self.make(hours)
        {
            "uuid"          => SecureRandom.uuid,
            "hours"         => hours,
            "lastResetTime" => Time.new.to_i,
            "capsule"       => SecureRandom.hex
        }
    end

    # TxEngines::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        hours = LucilleCore::askQuestionAnswerAsString("weekly hours (empty for abort): ")
        return nil if hours == ""
        hours = hours.to_f
        return nil if hours == 0
        TxEngines::make(hours)
    end

    # -----------------------------------------------
    # Data

    # TxEngines::listingCompletionRatio(engine)
    def self.listingCompletionRatio(engine)
        return 1 if TxEngines::periodCompletionRatio(engine) >= 1
        Bank::recoveredAverageHoursPerDay(engine["uuid"]).to_f/(engine["hours"].to_f/6)
    end

    # TxEngines::periodCompletionRatio(engine)
    def self.periodCompletionRatio(engine)
        Bank::getValue(engine["capsule"]).to_f/(engine["hours"]*3600)
    end

    # TxEngines::toString(engine)
    def self.toString(engine)
        strings = []

        strings << "period: #{"#{"%6.2f" % (100*TxEngines::periodCompletionRatio(engine))}%".green} of #{"%5.2f" % engine["hours"]} hours"

        hasReachedObjective = Bank::getValue(engine["capsule"]) >= engine["hours"]*3600
        timeSinceResetInDays = (Time.new.to_i - engine["lastResetTime"]).to_f/86400
        itHassBeenAWeek = timeSinceResetInDays >= 7

        if hasReachedObjective and itHassBeenAWeek then
            strings << ", awaiting data management"
        end

        if hasReachedObjective and !itHassBeenAWeek then
            strings << ", objective met, #{(7 - timeSinceResetInDays).round(2)} days before reset"
        end

        if !hasReachedObjective and !itHassBeenAWeek then
            strings << ", #{(engine["hours"] - Bank::getValue(engine["capsule"]).to_f/3600).round(2)} hours to go, #{(7 - timeSinceResetInDays).round(2)} days left in period"
        end

        if !hasReachedObjective and itHassBeenAWeek then
            strings << ", late by #{(timeSinceResetInDays-7).round(2)} days"
        end

        strings << ""
        strings.join()
    end

    # TxEngines::shouldListing(item)
    def self.shouldListing(item)
        raise "(error: 8977-c65c6f3f720f)" if item["engine-0916"].nil?
        if item["core-1919"] then
            core = Catalyst::itemOrNull(item["core-1919"])
            if core.nil? then
                Updates::itemAttributeUpdate(uuid, "core-1919", nil)
                TxEngines::listingCompletionRatio(item["engine-0916"]) < 1
            else
                b1 = TxEngines::listingCompletionRatio(item["engine-0916"]) < 1
                b2 = TxEngines::listingCompletionRatio(core["engine-0916"]) < 1
                b1 and b2
            end
        else
            TxEngines::listingCompletionRatio(item["engine-0916"]) < 1
        end
    end

    # -----------------------------------------------
    # Ops

    # TxEngines::maintenance1(engine, description) # engine or null
    def self.maintenance1(engine, description)
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
        engine
    end

    # TxEngines::prefix1(item)
    def self.prefix1(item)
        return "" if item["engine-0916"].nil?
        "(engine: #{TxEngines::toString(item["engine-0916"]).green}) "
    end

    # TxEngines::prefix2(item)
    def self.prefix2(item)
        return "" if item["engine-0916"].nil?
        "(engine: #{"%6.2f" % (100*TxEngines::listingCompletionRatio(item["engine-0916"]))} %) ".green
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
