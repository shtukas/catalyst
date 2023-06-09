
class TxEngines

    # -------------------------
    # IO

    # TxEngines::makeEngine(uuid, hours)
    def self.makeEngine(uuid, hours)
        {
            "uuid"          => uuid,
            "hours"         => hours,
            "lastResetTime" => 0,
            "capsule"       => SecureRandom.hex # used for the time management
        }
    end

    # TxEngines::interactivelyMakeEngineOrDefault()
    def self.interactivelyMakeEngineOrDefault()
        uuid = SecureRandom.uuid
        hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
        TxEngines::makeEngine(uuid, hours)
    end

    # -------------------------
    # Data

    # TxEngines::dayCompletionRatio(engine)
    def self.dayCompletionRatio(engine)
        Bank::getValueAtDate(engine["uuid"], CommonUtils::today()).to_f/((engine["hours"]*3600).to_f/5)
    end

    # TxEngines::periodCompletionRatio(engine)
    def self.periodCompletionRatio(engine)
        Bank::getValue(engine["capsule"]).to_f/(engine["hours"]*3600)
    end

    # TxEngines::listingCompletionRatio(engine)
    def self.listingCompletionRatio(engine)
        period = TxEngines::periodCompletionRatio(engine)
        return period if period >= 1
        day = TxEngines::dayCompletionRatio(engine)
        return day if day >= 1
        0.9*day + 0.1*period
    end

    # TxEngines::toString0(engine)
    def self.toString0(engine)
        "(engine) #{engine["description"]}"
    end

    # TxEngines::toString1(engine)
    def self.toString1(engine)
        strings = []

        strings << "(engine: today: #{"#{"%5.2f" % (100*TxEngines::dayCompletionRatio(engine))}%".green} of #{"%5.2f" % (engine["hours"].to_f/5)} hours"
        strings << ", period: #{"#{"%5.2f" % (100*TxEngines::periodCompletionRatio(engine))}%".green} of #{"%5.2f" % engine["hours"]} hours"

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

        strings << ")"
        strings.join()
    end

    # TxEngines::pendingEngines()
    def self.pendingEngines()
        Solingen::mikuTypeItems("TxEngine")
            .select{|engine| TxEngines::listingCompletionRatio(engine) < 1 }
            .select{|engine| DoNotShowUntil::isVisible(engine) }
    end

    # TxEngines::listingItems()
    def self.listingItems()
        Solingen::mikuTypeItems("TxEngine")
            .sort_by{|engine| TxEngines::listingCompletionRatio(engine) }
    end

    # TxEngines::engineToListingTasks(engine)
    def self.engineToListingTasks(engine)
        TxEngines::engineUUIDOptToCliques(engine["uuid"])
            .sort_by{|clique| Bank::recoveredAverageHoursPerDay(clique["uuid"]) }
            .map{|clique|
                NxOrbitals::orbitalToNxTasks(clique)
                    .sort_by{|task| task["position"] }
            }
            .flatten
    end

    # TxEngines::itemsForProgram0(engine)
    def self.itemsForProgram0(engine)

        burners = Solingen::mikuTypeItems("NxBurner")
                    .select{|burner| burner["engineuuid"] == engine["uuid"] }

        fires = Solingen::mikuTypeItems("NxFire")
                    .select{|burner| burner["engineuuid"] == engine["uuid"] }

        waves = Waves::listingItems()
                    .select{|burner| burner["engineuuid"] == engine["uuid"] }

        ondates = NxOndates::listingItems()
                    .select{|burner| burner["engineuuid"] == engine["uuid"] }

        tasks = TxEngines::engineToListingTasks(engine)

        [
            Desktop::listingItems(),
            burners,
            fires,
            waves,
            ondates,
            tasks
        ]
            .flatten
            .select{|item| Listing::listable(item) }
            .reduce([]){|selected, item|
                if !selected.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected + [item]
                else
                    selected
                end
            }
    end

    # TxEngines::itemToEngineSuffix(item)
    def self.itemToEngineSuffix(item)
        if item["engineuuid"] then
            engine = Solingen::getItemOrNull(item["engineuuid"])
            if engine.nil? then
                Solingen::setAttribute2(item["uuid"], "engineuuid", nil)
                ""
            else
                " #{"(#{engine["description"]})".green}"
            end
        else
            ""
        end
    end

    # TxEngines::engineUUIDOptToCliques(engineuuidOpt)
    def self.engineUUIDOptToCliques(engineuuidOpt)
        Solingen::mikuTypeItems("NxOrbital")
            .select{|clique| clique["engineuuid"] == engineuuidOpt }
    end

    # TxEngines::engineToCliques(engine)
    def self.engineToCliques(engine)
        Solingen::mikuTypeItems("NxOrbital")
            .select{|clique| clique["engineuuid"] == engine["uuid"] }
    end

    # -------------------------
    # Ops

    # TxEngines::interactivelySelectEngineTypeOrNull()
    def self.interactivelySelectEngineTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("engine type", ["daily-recovery-time (default, with to 1 hour)", "weekly-time"])
    end

    # TxEngines::engineMaintenance(engine)
    def self.engineMaintenance(engine)
        if engine["type"] == "daily-recovery-time" then
            return nil
        end
        if engine["type"] == "weekly-time" then
            return nil if Bank::getValue(engine["capsule"]).to_f/3600 < engine["hours"]
            return nil if (Time.new.to_i - engine["lastResetTime"]) < 86400*7
            if Bank::getValue(engine["capsule"]).to_f/3600 > 1.5*engine["hours"] then
                overflow = 0.5*engine["hours"]*3600
                puts "I am about to smooth engine #{TxEngines::toString1(engine)}, overflow: #{(overflow.to_f/3600).round(2)} hours for engine: #{engine["description"]}"
                LucilleCore::pressEnterToContinue()
                NxTimePromises::issue_things(engine, overflow, 20)
                return nil
            end
            puts "> I am about to reset engine: #{TxEngines::toString1(engine)}"
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
        raise "could not TxEngines::engineMaintenance(engine) for engine: #{engine}, engine: #{engine}"
    end

    # TxEngines::ensureEachCliqueOfAnEngineHasAName()
    def self.ensureEachCliqueOfAnEngineHasAName()
        Solingen::mikuTypeItems("TxEngine").each{|engine|
            TxEngines::engineUUIDOptToCliques(engine["uuid"]).each{|clique|
                if clique["description"].nil? then
                    description = nil
                    loop {
                        description = LucilleCore::askQuestionAnswerAsString("description: ")
                        break if description != ""
                    }
                    Solingen::setAttribute2(clique["uuid"], "description", description)
                end
            }
        }
    end

    # TxEngines::generalMaintenance()
    def self.generalMaintenance()
        TxEngines::ensureEachCliqueOfAnEngineHasAName()
        Solingen::mikuTypeItems("TxEngine").each{|engine| TxEngines::engineMaintenance(engine) }
    end

    # TxEngines::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("engine", Solingen::mikuTypeItems("TxEngine"), lambda{|item| TxEngines::toString0(item) })
    end

    # TxEngines::interactivelySelectOneUUIDOrNull()
    def self.interactivelySelectOneUUIDOrNull()
        engine = TxEngines::interactivelySelectOneOrNull()
        return engine["uuid"] if engine
        nil
    end

    # TxEngines::program1(engine)
    def self.program1(engine)
        loop {
            actions = ["reset hours", "add time", "cliques"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
            return if action.nil?
            if action == "reset hours" then
                hours = LucilleCore::askQuestionAnswerAsString("hours (empty to abort): ")
                return if hours == ""
                hours = hours.to_f
                Solingen::setAttribute2(engine["uuid"], "hours", hours)
            end
            if action == "cliques" then
                loop {
                    cliques = TxEngines::engineToCliques(engine)
                                .sort_by{|item| item["description"] }
                    clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", cliques, lambda{|clique| NxOrbitals::toString(clique) })
                    break if clique.nil?
                    NxOrbitals::program2(clique)
                }
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                PolyActions::addTimeToItem(engine, timeInHours*3600)
            end
        }
    end
end
