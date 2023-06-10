
class NxCores

    # -------------------------
    # IO

    # NxCores::makeCore(uuid, description, hours)
    def self.makeCore(uuid, description, hours)
        {
            "uuid"          => uuid,
            "mikuType"      => "NxCore",
            "description"   => description,
            "hours"         => hours,
            "lastResetTime" => 0,
            "capsule"       => SecureRandom.hex # used for the time management
        }
    end

    # NxCores::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("core description (empty for abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        hours = LucilleCore::askQuestionAnswerAsString("hours: ")
        return nil if hours == ""
        hours = hours.to_f
        if hours == 0 then
            puts "hours cannot be zero"
            LucilleCore::pressEnterToContinue()
            return NxCores::interactivelyIssueNewOrNull()
        end
        core = NxCores::makeCore(uuid, hours)
        DarkEnergy::commit(core)
        core
    end

    # -------------------------
    # Data

    # NxCores::dayCompletionRatio(core)
    def self.dayCompletionRatio(core)
        Bank::getValueAtDate(core["uuid"], CommonUtils::today()).to_f/((core["hours"]*3600).to_f/5)
    end

    # NxCores::periodCompletionRatio(core)
    def self.periodCompletionRatio(core)
        Bank::getValue(core["capsule"]).to_f/(core["hours"]*3600)
    end

    # NxCores::listingCompletionRatio(core)
    def self.listingCompletionRatio(core)
        period = NxCores::periodCompletionRatio(core)
        return period if period >= 1
        day = NxCores::dayCompletionRatio(core)
        return day if day >= 1
        0.9*day + 0.1*period
    end

    # NxCores::toString0(core)
    def self.toString0(core)
        "(core) #{core["description"]}"
    end

    # NxCores::toString1(core)
    def self.toString1(core)
        strings = []

        strings << "(core: today: #{"#{"%5.2f" % (100*NxCores::dayCompletionRatio(core))}%".green} of #{"%5.2f" % (core["hours"].to_f/5)} hours"
        strings << ", period: #{"#{"%5.2f" % (100*NxCores::periodCompletionRatio(core))}%".green} of #{"%5.2f" % core["hours"]} hours"

        hasReachedObjective = Bank::getValue(core["capsule"]) >= core["hours"]*3600
        timeSinceResetInDays = (Time.new.to_i - core["lastResetTime"]).to_f/86400
        itHassBeenAWeek = timeSinceResetInDays >= 7

        if hasReachedObjective and itHassBeenAWeek then
            strings << ", awaiting data management"
        end

        if hasReachedObjective and !itHassBeenAWeek then
            strings << ", objective met, #{(7 - timeSinceResetInDays).round(2)} days before reset"
        end

        if !hasReachedObjective and !itHassBeenAWeek then
            strings << ", #{(core["hours"] - Bank::getValue(core["capsule"]).to_f/3600).round(2)} hours to go, #{(7 - timeSinceResetInDays).round(2)} days left in period"
        end

        if !hasReachedObjective and itHassBeenAWeek then
            strings << ", late by #{(timeSinceResetInDays-7).round(2)} days"
        end

        strings << ")"
        strings.join()
    end

    # NxCores::pendingEngines()
    def self.pendingEngines()
        DarkEnergy::mikuType("NxCore")
            .select{|core| NxCores::listingCompletionRatio(core) < 1 }
            .select{|core| DoNotShowUntil::isVisible(core) }
    end

    # NxCores::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxCore")
            .sort_by{|core| NxCores::listingCompletionRatio(core) }
    end

    # NxCores::coreToContents(core)
    def self.coreToContents(core)

    end

    # NxCores::coreToEngineSuffix(item)
    def self.coreToEngineSuffix(item)
        if item["coreuuid"] then
            core = DarkEnergy::itemOrNull(item["coreuuid"])
            if core.nil? then
                DarkEnergy::patch(item["uuid"], "coreuuid", nil)
                ""
            else
                " #{"(#{core["description"]})".green}"
            end
        else
            ""
        end
    end

    # -------------------------
    # Ops

    # NxCores::coreMaintenance(core)
    def self.coreMaintenance(core)
        return nil if Bank::getValue(core["capsule"]).to_f/3600 < core["hours"]
        return nil if (Time.new.to_i - core["lastResetTime"]) < 86400*7
        if Bank::getValue(core["capsule"]).to_f/3600 > 1.5*core["hours"] then
            overflow = 0.5*core["hours"]*3600
            puts "I am about to smooth core #{NxCores::toString1(core)}, overflow: #{(overflow.to_f/3600).round(2)} hours for core: #{core["description"]}"
            LucilleCore::pressEnterToContinue()
            NxTimePromises::issue_things(core, overflow, 20)
            return nil
        end
        puts "> I am about to reset core: #{NxCores::toString1(core)}"
        LucilleCore::pressEnterToContinue()
        Bank::put(core["capsule"], -core["hours"]*3600)
        if !LucilleCore::askQuestionAnswerAsBoolean("> continue with #{core["hours"]} hours ? ") then
            hours = LucilleCore::askQuestionAnswerAsString("specify period load in hours (empty for the current value): ")
            if hours.size > 0 then
                core["hours"] = hours.to_f
            end
        end
        core["lastResetTime"] = Time.new.to_i
        core
    end


    # NxCores::generalMaintenance()
    def self.generalMaintenance()
        DarkEnergy::mikuType("NxCore").each{|core| NxCores::coreMaintenance(core) }
    end

    # NxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", DarkEnergy::mikuType("NxCore"), lambda{|item| NxCores::toString0(item) })
    end

    # NxCores::interactivelySelectOneUUIDOrNull()
    def self.interactivelySelectOneUUIDOrNull()
        core = NxCores::interactivelySelectOneOrNull()
        return nil if core.nil?
        core
    end

    # NxCores::program0(core)
    def self.program0(core)
        puts "NxCores::program0(core) needs to be implemented"
        LucilleCore::pressEnterToContinue()
    end

    # NxCores::program1(core)
    def self.program1(core)
        loop {
            actions = ["add time", "program"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
            return if action.nil?
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                PolyActions::addTimeToItem(core, timeInHours*3600)
            end
            if action == "program" then
                NxCores::program0(core)
            end
        }
    end
end
