
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
        Events::publishItemInit(core["mikuType"], core["uuid"])
        core.to_a.each{|key, value|
            Events::publishItemAttributeUpdate(core["uuid"], key, value)
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

        padding = XCache::getOrDefaultValue("bf986315-dfd7-44e2-8f00-ebea0271e2b2", "0").to_i

        strings << "⏱️  #{core["description"].ljust(padding)}: today: #{"#{"%6.2f" % (100*Catalyst::listingCompletionRatio(core))}%".green} of #{"%5.2f" % (core["hours"].to_f/5)} hours"
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
        cores = Catalyst::mikuType("TxCore")
                    .sort_by {|core| Catalyst::listingCompletionRatio(core) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|core| TxCores::toString(core) })
    end

    # TxCores::listingItems()
    def self.listingItems()
        Catalyst::mikuType("TxCore")
            .sort_by{|core| Catalyst::listingCompletionRatio(core) }
    end

    # TxCores::suffix(item)
    def self.suffix(item)
        return "" if item["coreX-2300"].nil?
        core = Catalyst::itemOrNull(item["coreX-2300"])
        return "" if core.nil?
        " (#{core["description"]})".yellow
    end

    # TxCores::childrenInOrder(core)
    def self.childrenInOrder(core)
        (Catalyst::mikuType("NxTask")+Catalyst::mikuType("NxClique"))
            .select{|item| item["coreX-2300"] == core["uuid"] }
            .sort_by{|item| item["global-position"] }
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
        Events::publishItemAttributeUpdate(core["uuid"], "hours", core["hours"])
        Events::publishItemAttributeUpdate(core["uuid"], "lastResetTime", core["lastResetTime"])
    end

    # TxCores::maintenance2()
    def self.maintenance2()
        Catalyst::mikuType("TxCore").each{|core| TxCores::maintenance1(core) }
    end

    # TxCores::maintenance3()
    def self.maintenance3()
        padding = (Catalyst::mikuType("TxCore").map{|core| core["description"].size } + [0]).max
        XCache::set("bf986315-dfd7-44e2-8f00-ebea0271e2b2", padding)
    end

    # TxCores::pile3(core)
    def self.pile3(core)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.uuid, line)
                puts JSON.pretty_generate(task)
                Events::publishItemAttributeUpdate(task["uuid"], "coreX-2300", core["uuid"])
            }
    end

    # TxCores::program1(core)
    def self.program1(core)
        loop {

            core = Catalyst::itemOrNull(core["uuid"])
            return if core.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(core, false)
            puts  Listing::toString2(store, core)
            puts  ""

            Prefix::prefix(TxCores::childrenInOrder(core))
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            puts "task | sort"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "pile" then
                TxCores::pile3(core)
                next
            end

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Events::publishItemAttributeUpdate(task["uuid"], "coreX-2300", core["uuid"])
                next
            end

            if Interpreting::match("sort", input) then
                items = TxCores::childrenInOrder(core)
                selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    Events::publishItemAttributeUpdate(item["uuid"], "global-position", Catalyst::newGlobalFirstPosition())
                }
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # TxCores::program2()
    def self.program2()
        loop {
            core = TxCores::interactivelySelectOneOrNull()
            return if core.nil?
            TxCores::program1(core)
        }
    end
end
