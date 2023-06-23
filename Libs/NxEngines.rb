class NxEngines

    # NxEngines::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()
        hours = LucilleCore::askQuestionAnswerAsString("hours (per week): ").to_f
        DarkEnergy::init("NxEngine", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::patch(uuid, "hours", hours)
        DarkEnergy::patch(uuid, "lastResetTime", 0)
        DarkEnergy::patch(uuid, "capsule", SecureRandom.hex)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxEngines::toNumbersString(engine)
    def self.toNumbersString(engine)
        strings = []

        strings << "today: #{"#{"%6.2f" % (100*NxCores::dayCompletionRatio(engine))}%".green} of #{"%5.2f" % (engine["hours"].to_f/5)} hours"
        strings << ", period: #{"#{"%6.2f" % (100*NxCores::periodCompletionRatio(engine))}%".green} of #{"%5.2f" % engine["hours"]} hours"

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

        strings.join()
    end

    # NxEngines::toString(engine)
    def self.toString(engine)
        "⚙️  (#{NxEngines::toNumbersString(engine)}) #{engine["description"]}#{CoreData::itemToSuffixString(engine)}"
    end

    # NxEngines::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxEngine")
            .select{|engine| NxCores::listingCompletionRatio(engine) < 1 }
            .sort_by{|engine| NxCores::listingCompletionRatio(engine) }
    end

    # NxEngines::program2(engine)
    def self.program2(engine)
        loop {
            system("clear")
            puts NxEngines::toString(engine)
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["start", "destroy"])
            return if action.nil?
            if action == "start" then
                NxBalls::start(item)
            end
            if action == "destroy" then
                NxBalls::stop(item)
                if LucilleCore::askQuestionAnswerAsBoolean("destroy: '#{NxEngines::toString(engine).green} ? '", true) then
                    DarkEnergy::destroy(engine["uuid"])
                end
            end
        }
    end

    # NxEngines::program()
    def self.program()
        loop {
            engines = DarkEnergy::mikuType("NxEngine")
            if engines.empty? then
                puts "no deadline found"
                LucilleCore::pressEnterToContinue()
                return
            end
            engine = LucilleCore::selectEntityFromListOfEntitiesOrNull("engine", engines, lambda{|engine| NxEngines::toString(engine) })
            return if engine.nil?
            NxEngines::program2(engine)
        }
    end

    # NxEngines::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("NxEngine").each{|engine| Mechanics::engine_maintenance(engine) }
    end
end