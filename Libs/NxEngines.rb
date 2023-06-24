
class NxEngines

    # -------------------------

    # NxEngines::griduuid()
    def self.griduuid()
        "f96cc544-06ef-4e30-b415-e57e78eb3d73"
    end

    # NxEngines::grid()
    def self.grid()
        engine = DarkEnergy::itemOrNull(NxEngines::griduuid())
        if engine.nil? then
            raise "(error: 7320289f-10c4-49c9-8f50-1f5fa22fcb5a) could not find reverse infinity engine"
        end
        engine
    end
 
    # NxEngines::gridChildren()
    def self.gridChildren()
        Memoize::evaluate(
            "32ab7fb3-f85c-4fdf-aafe-9465d7db2f5f", 
            lambda{
                puts "Computing Pure::bottom() ..."
                items = DarkEnergy::mikuType("NxTask")
                                .select{|task| task["parent"].nil? }
                                .select{|task| task["engine"].nil? }
                                .select{|task| task["deadline"].nil? }
                                .sort_by{|item| item["unixtime"] }
                (items.take(100) + items.reverse.take(100)).shuffle
            })
            .select{|item| DarkEnergy::itemOrNull(item["uuid"]) }
            .compact
    end

    # NxEngines::itemBelongsToEnergyGrid(item)
    def self.itemBelongsToEnergyGrid(item)
        NxEngines::gridChildren().map{|item| item["uuid"] }.include?(item["uuid"])
    end

    # -------------------------

    # NxEngines::infinityDepth()
    def self.infinityDepth()
        100
    end

    # -------------------------
    # IO

    # NxEngines::make(uuid, description, hours)
    def self.make(uuid, description, hours)
        {
            "uuid"          => uuid,
            "mikuType"      => "NxEngine",
            "description"   => description,
            "hours"         => hours,
            "lastResetTime" => 0,
            "capsule"       => SecureRandom.hex # used for the time management
        }
    end

    # NxEngines::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("engine description (empty for abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
        return nil if hours == ""
        hours = hours.to_f
        if hours == 0 then
            puts "hours cannot be zero"
            LucilleCore::pressEnterToContinue()
            return NxEngines::interactivelyIssueNewOrNull()
        end
        engine = NxEngines::make(uuid, description, hours)
        DarkEnergy::commit(engine)
        engine
    end

    # -------------------------
    # Data

    # NxEngines::dayCompletionRatio(engine)
    def self.dayCompletionRatio(engine)
        Bank::getValueAtDate(engine["uuid"], CommonUtils::today()).to_f/((engine["hours"]*3600).to_f/5)
    end

    # NxEngines::periodCompletionRatio(engine)
    def self.periodCompletionRatio(engine)
        Bank::getValue(engine["capsule"]).to_f/(engine["hours"]*3600)
    end

    # NxEngines::listingCompletionRatio(engine)
    def self.listingCompletionRatio(engine)
        Memoize::evaluate("f8dfa87e-75a2-4e49-86d8-634134727687:#{engine["uuid"]}", lambda{
            period = NxEngines::periodCompletionRatio(engine)
            return period if period >= 1
            day = NxEngines::dayCompletionRatio(engine)
            return day if day >= 1
            0.9*day + 0.1*period
        })
    end

    # NxEngines::toString(engine)
    def self.toString(engine)
        padding = XCache::getOrDefaultValue("0e067f3e-a954-4138-8336-876240b9b7dd", "0").to_i
        strings = []

        strings << "⏱️  #{engine["description"].ljust(padding)} (engine: today: #{"#{"%6.2f" % (100*NxEngines::dayCompletionRatio(engine))}%".green} of #{"%5.2f" % (engine["hours"].to_f/5)} hours"
        strings << ", period: #{"#{"%6.2f" % (100*NxEngines::periodCompletionRatio(engine))}%".green} of #{"%5.2f" % engine["hours"]} hours"

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

    # NxEngines::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxEngine")
            .select{|engine| NxEngines::listingCompletionRatio(engine) < 1 }
            .sort_by{|engine| NxEngines::listingCompletionRatio(engine) }
    end

    # NxEngines::children(engine)
    def self.children(engine)
        if engine["uuid"] == NxEngines::griduuid() then
            return NxEngines::gridChildren()
        end

        items = DarkEnergy::all()
                    .select{|item| item["parent"] }
                    .select{|item| item["parent"]["uuid"] == engine["uuid"] }

        burners, items = items.partition{|item| item["mikuType"] == "NxBurner" }
        ondates, items = items.partition{|item| item["mikuType"] == "NxOndate" }
        waves,   items = items.partition{|item| item["mikuType"] == "Wave" }
        tasks,  things = items.partition{|item| item["mikuType"] == "NxTask" }

        tasks = tasks.sort_by{|item| item["parent"]["position"] }

        things + burners + ondates + waves + tasks
     end

    # NxEngines::getItemCoreOrNull(item)
    def self.getItemCoreOrNull(item)
        return nil if item["parent"].nil?
        parent = DarkEnergy::itemOrNull(item["parent"]["uuid"])
        return nil if parent["mikuType"] != "NxEngine"
        parent
    end

    # -------------------------
    # Ops

    # NxEngines::maintenance_all_instances()
    def self.maintenance_all_instances()
        padding = DarkEnergy::mikuType("NxEngine").map{|engine| engine["description"].size }.max
        XCache::set("0e067f3e-a954-4138-8336-876240b9b7dd", padding)
    end

    # NxEngines::maintenance_leader_instance()
    def self.maintenance_leader_instance()
        DarkEnergy::mikuType("NxEngine").each{|engine| Mechanics::engine_maintenance(engine) }
    end

    # NxEngines::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        engines = DarkEnergy::mikuType("NxEngine")
                    .reject{|engine| engine["uuid"] == NxEngines::griduuid() }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("engine", engines, lambda{|item| item["description"] })
    end

    # NxEngines::program0(engine)
    def self.program0(engine)
        loop {

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            spacecontrol.putsline "engine:"
            store.register(engine, false)
            spacecontrol.putsline Listing::itemToListingLine(store, engine)

            spacecontrol.putsline ""
            items = NxEngines::children(engine)
            Listing::printing(spacecontrol, store, items)

            spacecontrol.putsline ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                position = Tx8s::interactivelyDecidePositionUnderThisParent(engine)
                task["parent"] = Tx8s::make(engine["uuid"], position)
                DarkEnergy::commit(task)
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxEngines::program()
    def self.program()
        loop {
            engines = DarkEnergy::mikuType("NxEngine").sort_by{|engine| NxEngines::listingCompletionRatio(engine) }
            engine = LucilleCore::selectEntityFromListOfEntitiesOrNull("engine", engines, lambda{|engine| NxEngines::toString(engine) })
            break if engine.nil?
            NxEngines::program0(engine)
        }
    end

    # NxEngines::askAndThenGiveCoreToItemAttempt(item)
    def self.askAndThenGiveCoreToItemAttempt(item)
        if LucilleCore::askQuestionAnswerAsBoolean("> Add engine ? ", false) then
            NxEngines::interactivelySetCoreAttempt(item)
        end
    end

    # NxEngines::interactivelySetCoreAttempt(item)
    def self.interactivelySetCoreAttempt(item)
        if item["mikuType"] == "NxEngine" then
            puts "You cannot give a engine to a NxEngine"
            LucilleCore::pressEnterToContinue()
            return
        end
        engine = NxEngines::interactivelySelectOneOrNull()
        return if engine.nil?
        DarkEnergy::patch(item["uuid"], "parent", Tx8s::make(engine["uuid"], rand))
    end
end





