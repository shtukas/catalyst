
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
        Cubes::init(nil, core["mikuType"], core["uuid"])
        core.to_a.each{|key, value|
            Cubes::setAttribute2(core["uuid"], key, value)
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
        cores = Cubes::mikuType("TxCore")
                    .sort_by {|core| Catalyst::listingCompletionRatio(core) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|core| TxCores::toString(core) })
    end

    # TxCores::coresForListing()
    def self.coresForListing()
        Cubes::mikuType("TxCore")
            .select{|core| Catalyst::listingCompletionRatio(core) < 1 }
            .sort_by{|core| Catalyst::listingCompletionRatio(core) }
    end

    # TxCores::elementsInOrder(core)
    def self.elementsInOrder(core)
        Cubes::mikuType("NxThread")
            .select{|item| item["lineage-nx128"] == core["uuid"] }
            .sort_by{|item| item["coordinate-nx129"] || 0 }
    end

    # TxCores::newFirstPosition(core)
    def self.newFirstPosition(core)
        elements = TxCores::elementsInOrder(core)
                        .select{|item| item["coordinate-nx129"] }
        return 1 if elements.empty?
        elements.map{|item| item["coordinate-nx129"] }.min - 1
    end

    # TxCores::newNextPosition(core)
    def self.newNextPosition(core)
        elements = NxThreads::elementsInOrder(core)
                        .select{|item| item["coordinate-nx129"] }
        return 1 if elements.empty?
        elements.map{|item| item["coordinate-nx129"] }.max
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
        Cubes::setAttribute2(core["uuid"], "hours", core["hours"])
        Cubes::setAttribute2(core["uuid"], "lastResetTime", core["lastResetTime"])
    end

    # TxCores::maintenance2()
    def self.maintenance2()
        Cubes::mikuType("TxCore").each{|core| TxCores::maintenance1(core) }
        padding = (Cubes::mikuType("TxCore").map{|core| core["description"].size } + [0]).max
        XCache::set("bf986315-dfd7-44e2-8f00-ebea0271e2b2", padding)
    end

    # TxCores::program1(core)
    def self.program1(core)
        loop {

            core = Cubes::itemOrNull(core["uuid"])
            return if core.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            store.register(core, false)
            spacecontrol.putsline Listing::toString2(store, core)
            spacecontrol.putsline ""

            TxCores::elementsInOrder(core)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::toString2(store, item).gsub("(#{core["description"]})", "")
                    break if !status
                }

            puts ""
            puts "(thread, position * *, sort)"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "thread" then
                position = TxCores::newNextPosition(core)
                thread = NxThreads::interactivelyIssueNewOrNull()
                next if thread.nil?
                Cubes::setAttribute2(thread["uuid"], "lineage-nx128", core["uuid"])
                Cubes::setAttribute2(thread["uuid"], "coordinate-nx129", position)
                next
            end

            if Interpreting::match("position * *", input) then
                _, listord, position = Interpreting::tokenizer(input)
                item = store.get(listord.to_i)
                return if item.nil?
                Cubes::setAttribute2(item["uuid"], "coordinate-nx129", position.to_f)
                return
            end

            if input == "sort" then
                unselected = TxCores::elementsInOrder(core)
                selected, _ = LucilleCore::selectZeroOrMore("item", [], unselected, lambda{ |item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    Cubes::setAttribute2(task["uuid"], "coordinate-nx129",  TxCores::newFirstPosition(core))
                }
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
