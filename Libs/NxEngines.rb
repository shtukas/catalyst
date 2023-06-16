
class NxEngines

    # NxEngines::interactivelyIssueNewForItem(item)
    def self.interactivelyIssueNewForItem(item)
        uuid = SecureRandom.uuid
        hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
        DarkEnergy::init("NxEngine", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "targetuuid", item["uuid"])
        DarkEnergy::patch(uuid, "hours", hours)
        DarkEnergy::patch(uuid, "lastResetTime", 0)
        DarkEnergy::patch(uuid, "capsule", SecureRandom.hex)

        DarkEnergy::patch(item["uuid"], "engine", uuid) # we need to mark the item with the engine

        DarkEnergy::itemOrNull(uuid)
    end

    # NxEngines::toString(engine)
    def self.toString(engine)
        strings = []

        strings << "⚙️  (engine) today: #{"#{"%6.2f" % (100*NxCores::dayCompletionRatio(engine))}%".green} of #{"%5.2f" % (engine["hours"].to_f/5)} hours"
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

        strings << ")"

        target = DarkEnergy::itemOrNull(engine["targetuuid"])
        if target then
            strings << " #{target["description"]}"
        end

        strings.join()
    end

    # NxEngines::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxEngine")
            .select{|engine| NxCores::listingCompletionRatio(engine) < 1 }
            .sort_by{|engine| NxCores::listingCompletionRatio(engine) }
    end

    # NxEngines::program0()
    def self.program0()
        loop {
            engines = DarkEnergy::mikuType("NxEngine")
            if engines.empty? then
                puts "no deadline found"
                LucilleCore::pressEnterToContinue()
                return
            end
            engine = LucilleCore::selectEntityFromListOfEntitiesOrNull("engine", engines, lambda{|engine| NxEngines::toString(engine) })
            return if engine.nil?
            target = DarkEnergy::itemOrNull(engine["targetuuid"])
            next if target.nil?
            PolyActions::program(target)
        }
    end

    # NxEngines::attachEngineAttempt(item)
    def self.attachEngineAttempt(item)
        NxEngines::interactivelyIssueNewForItem(item)
    end

    # NxEngines::askAndThenAttachEngineToItemAttempt(item)
    def self.askAndThenAttachEngineToItemAttempt(item)
        if LucilleCore::askQuestionAnswerAsBoolean("> add engine ? ", false) then
            NxEngines::attachEngineAttempt(item)
        end
    end

    # NxEngines::suffix(item)
    def self.suffix(item)
        return "" if item["engine"].nil?
        engine = DarkEnergy::itemOrNull(item["engine"])
        return "" if engine.nil?
        " #{NxEngines::toString(engine)}"
    end
end
