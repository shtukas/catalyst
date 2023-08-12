
class TxCores

    # -----------------------------------------------
    # Build

    # TxCores::make(uuid, description, hours, capsule)
    def self.make(uuid, description, hours, capsule)
        {
            "uuid"          => uuid,
            "mikuType"      => "TxCore",
            "description"   => description,
            "hours"         => hours.to_f,
            "lastResetTime" => Time.new.to_f,
            "capsule"       => capsule
        }
    end

    # TxCores::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("weekly hours (empty for abort): ")
        return nil if hours == ""
        return nil if hours == "0"
        TxCores::make(SecureRandom.uuid, description, hours, SecureRandom.hex)
    end

    # TxCores::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        core = TxCores::interactivelyMakeOrNull()
        BladesGI::init(core["mikuType"], core["uuid"])
        core.to_a.each{|key, value|
            BladesGI::setAttribute2(core["uuid"], key, value)
        }
    end

    # TxCores::interactivelyMakeEngine()
    def self.interactivelyMakeEngine()
        core = TxCores::interactivelyMakeOrNull()
        return core if core
        TxCores::interactivelyMakeEngine()
    end

    # -----------------------------------------------
    # Data

    # TxCores::periodCompletionRatio(core)
    def self.periodCompletionRatio(core)
        Bank::getValue(core["capsule"]).to_f/(core["hours"]*3600)
    end

    # TxCores::toString(core)
    def self.toString(core)
        strings = []

        strings << "⏱️  #{core["description"].ljust(20)}: today: #{"#{"%6.2f" % (100*Catalyst::listingCompletionRatio(core))}%".green} of #{"%5.2f" % (core["hours"].to_f/5)} hours"
        strings << ", period: #{"#{"%6.2f" % (100*TxCores::periodCompletionRatio(core))}%".green} of #{"%5.2f" % core["hours"]} hours"

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

        strings << ""
        strings.join()
    end

    # TxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        cores = BladesGI::mikuType("TxCore")
                    .sort_by {|core| Catalyst::listingCompletionRatio(core) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|core| TxCores::toString(core) })
    end

    # TxCores::listingItemsForCore(core)
    def self.listingItemsForCore(core)
        children = Tx8s::childrenInOrder(core)
        delegates = children.select{|item| item["mikuType"] == "NxDelegate" }
        tasks = children.select{|item| item["mikuType"] == "NxTask" }
        threads = children.select{|item| item["mikuType"] == "NxThread" }
        others = children.select{|item| !["NxDelegate", "NxThread", "NxTask"].include?(item["mikuType"]) }
        others + delegates + tasks.first(10) + threads
    end

    # -----------------------------------------------
    # Ops

    # TxCores::maintenance1(core) # core or null
    def self.maintenance1(core)
        return if NxBalls::itemIsActive(core)
        return nil if Bank::getValue(core["capsule"]).to_f/3600 < core["hours"]
        return nil if (Time.new.to_i - core["lastResetTime"]) < 86400*7
        puts "> I am about to reset core for #{core["description"]}"
        LucilleCore::pressEnterToContinue()
        Bank::put(core["capsule"], -core["hours"]*3600)
        if !LucilleCore::askQuestionAnswerAsBoolean("> continue with #{core["hours"]} hours ? ") then
            hours = LucilleCore::askQuestionAnswerAsString("specify period load in hours (empty for the current value): ")
            if hours.size > 0 then
                core["hours"] = hours.to_f
            end
        end
        core["lastResetTime"] = Time.new.to_i
        BladesGI::setAttribute2(core["uuid"], "hours", core["hours"])
        BladesGI::setAttribute2(core["uuid"], "lastResetTime", core["lastResetTime"])
    end

    # TxCores::maintenance3(core)
    def self.maintenance3(core)
        elements = Tx8s::childrenInOrder(core)
        return if elements.empty?
        min = elements.first["parent"]["position"]
        if min < 0 then
            elements.each{|element|
                tx8 = element["parent"]
                tx8["position"] = tx8["position"] + (-min)
                BladesGI::setAttribute2(element["uuid"], "parent", tx8)
            }
            return
        end
        if min >= 10 then
            elements.each{|element|
                tx8 = element["parent"]
                tx8["position"] = tx8["position"] - min
                BladesGI::setAttribute2(element["uuid"], "parent", tx8)
            }
            return
        end
    end

    # TxCores::maintenance2()
    def self.maintenance2()
        BladesGI::mikuType("TxCore").each{|core| TxCores::maintenance1(core) }
        BladesGI::mikuType("TxCore").each{|core| TxCores::maintenance3(core) }
    end

    # TxCores::program2()
    def self.program2()
        loop {
            core = TxCores::interactivelySelectOneOrNull()
            return if core.nil?
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", Tx8s::childrenInOrder(core), lambda{|item| PolyFunctions::toString(item) })
            next if item.nil?
            PolyActions::program(item)
        }
    end
end
