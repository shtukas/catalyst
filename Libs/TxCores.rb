
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

    # TxCores::interactivelyMakeEngine()
    def self.interactivelyMakeEngine()
        core = TxCores::interactivelyMakeOrNull()
        return core if core
        TxCores::interactivelyMakeEngine()
    end

    # -----------------------------------------------
    # Data

    # TxCores::dayCompletionRatio(core)
    def self.dayCompletionRatio(core)
        Bank::getValueAtDate(core["uuid"], CommonUtils::today()).to_f/((core["hours"]*3600).to_f/5)
    end

    # TxCores::periodCompletionRatio(core)
    def self.periodCompletionRatio(core)
        Bank::getValue(core["capsule"]).to_f/(core["hours"]*3600)
    end

    # TxCores::compositeCompletionRatio(core)
    def self.compositeCompletionRatio(core)
        period = TxCores::periodCompletionRatio(core)
        return period if period >= 1
        day = TxCores::dayCompletionRatio(core)
        return day if day >= 1
        0.9*day + 0.1*period
    end

    # TxCores::toString(core)
    def self.toString(core)
        strings = []

        strings << "⏱️  #{core["description"].ljust(20)}: today: #{"#{"%6.2f" % (100*TxCores::dayCompletionRatio(core))}%".green} of #{"%5.2f" % (core["hours"].to_f/5)} hours"
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
        cores = DarkEnergy::mikuType("TxCore")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|core| TxCores::toString(core) })
    end

    # TxCores::interactivelyAttempToAttachCore(item)
    def self.interactivelyAttempToAttachCore(item)
        core = TxCores::interactivelySelectOneOrNull()
        return if core.nil?
        if item["mikuType"] == "NxBooster" then
            Blades::setAttribute2(item["uuid"], "core", core["uuid"])
            return
        end
        item["core"] = core["uuid"]
        puts JSON.pretty_generate(item)
        DarkEnergy::commit(item)
    end

    # TxCores::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("TxCore")
            .sort_by{|core| TxCores::compositeCompletionRatio(core) }
    end

    # TxCores::childrenInOrder(core)
    def self.childrenInOrder(core)
        items  = Tx8s::childrenInOrder(core)
        pages, items  = items.partition{|item| item["mikuType"] == "NxPage" }
        floats, items = items.partition{|item| item["mikuType"] == "NxFloat" }
        threads, items = items.partition{|item| item["mikuType"] == "NxThread" }
        pages + floats + items + threads.sort_by{|th| NxThreads::completionRatio(th) }
    end

    # -----------------------------------------------
    # Ops

    # TxCores::maintenance1(core) # core or null
    def self.maintenance1(core)
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
        core
    end

    # TxCores::maintenance2()
    def self.maintenance2()
        DarkEnergy::mikuType("TxCore").each{|core| TxCores::maintenance1(core) }
    end

    # TxCores::suffix(item)
    def self.suffix(item)
        return "" if item["core"].nil?
        core = DarkEnergy::itemOrNull(item["core"])
        return "" if core.nil?
        " (#{core["description"].green})"
    end

    # TxCores::program1(core)
    def self.program1(core)
        loop {

            thread = DarkEnergy::itemOrNull(core["uuid"])
            return if core.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            store.register(core, false)
            spacecontrol.putsline Listing::toString2(store, core)
            spacecontrol.putsline ""

            TxCores::childrenInOrder(core)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::toString2(store, item).gsub(core["description"], "")
                    break if !status
                }

            puts ""
            puts "(task, pile, float, page, thread, position *)"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                NxTasks::interactivelyIssueNewAtParentOrNull(core)
                next
            end

            if input == "pile" then
                Tx8s::pileAtThisParent(core)
            end

            if input == "float" then
                NxFloats::interactivelyIssueNewAtParentOrNull(core)
                next
            end

            if input == "page" then
                NxPages::interactivelyIssueNewAtParentOrNull(core)
                next
            end

            if input == "thread" then
                NxThreads::interactivelyIssueNewAtParentOrNull(core)
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end
