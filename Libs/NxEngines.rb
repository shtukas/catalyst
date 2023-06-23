
class NxEngines

    # -------------------------

    # NxEngines::griduuid()
    def self.griduuid()
        "f96cc544-06ef-4e30-b415-e57e78eb3d73"
    end

    # NxEngines::grid()
    def self.grid()
        core = DarkEnergy::itemOrNull(NxEngines::griduuid())
        if core.nil? then
            raise "(error: 7320289f-10c4-49c9-8f50-1f5fa22fcb5a) could not find reverse infinity core"
        end
        core
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
            },
             86400
        )
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

    # NxEngines::makeCore(uuid, description, hours)
    def self.makeCore(uuid, description, hours)
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
        description = LucilleCore::askQuestionAnswerAsString("core description (empty for abort): ")
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
        core = NxEngines::makeCore(uuid, description, hours)
        DarkEnergy::commit(core)
        core
    end

    # -------------------------
    # Data

    # NxEngines::dayCompletionRatio(core)
    def self.dayCompletionRatio(core)
        Bank::getValueAtDate(core["uuid"], CommonUtils::today()).to_f/((core["hours"]*3600).to_f/5)
    end

    # NxEngines::periodCompletionRatio(core)
    def self.periodCompletionRatio(core)
        Bank::getValue(core["capsule"]).to_f/(core["hours"]*3600)
    end

    # NxEngines::listingCompletionRatio(core)
    def self.listingCompletionRatio(core)
        period = NxEngines::periodCompletionRatio(core)
        return period if period >= 1
        day = NxEngines::dayCompletionRatio(core)
        return day if day >= 1
        0.9*day + 0.1*period
    end

    # NxEngines::toString(core)
    def self.toString(core)
        padding = XCache::getOrDefaultValue("0e067f3e-a954-4138-8336-876240b9b7dd", "0").to_i
        strings = []

        strings << "⏱️  #{core["description"].ljust(padding)} (core: today: #{"#{"%6.2f" % (100*NxEngines::dayCompletionRatio(core))}%".green} of #{"%5.2f" % (core["hours"].to_f/5)} hours"
        strings << ", period: #{"#{"%6.2f" % (100*NxEngines::periodCompletionRatio(core))}%".green} of #{"%5.2f" % core["hours"]} hours"

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

    # NxEngines::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxEngine")
            .select{|core| NxEngines::listingCompletionRatio(core) < 1 }
            .sort_by{|core| NxEngines::listingCompletionRatio(core) }
    end

    # NxEngines::children(core)
    def self.children(core)
        if core["uuid"] == NxEngines::griduuid() then
            return NxEngines::gridChildren()
        end

        items = DarkEnergy::all()
                    .select{|item| item["parent"] }
                    .select{|item| item["parent"]["uuid"] == core["uuid"] }

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
        padding = DarkEnergy::mikuType("NxEngine").map{|core| core["description"].size }.max
        XCache::set("0e067f3e-a954-4138-8336-876240b9b7dd", padding)
    end

    # NxEngines::maintenance_leader_instance()
    def self.maintenance_leader_instance()
        DarkEnergy::mikuType("NxEngine").each{|core| Mechanics::engine_maintenance(core) }
    end

    # NxEngines::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        cores = DarkEnergy::mikuType("NxEngine")
                    .reject{|core| core["uuid"] == NxEngines::griduuid() }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|item| item["description"] })
    end

    # NxEngines::program0(core)
    def self.program0(core)
        loop {

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            spacecontrol.putsline "core:"
            store.register(core, false)
            spacecontrol.putsline Listing::itemToListingLine(store, core)

            spacecontrol.putsline ""
            items = NxEngines::children(core)
            Listing::printing(spacecontrol, store, items)

            spacecontrol.putsline ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                position = Tx8s::interactivelyDecidePositionUnderThisParent(core)
                task["parent"] = Tx8s::make(core["uuid"], position)
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
            cores = DarkEnergy::mikuType("NxEngine").sort_by{|core| NxEngines::listingCompletionRatio(core) }
            core = LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|core| NxEngines::toString(core) })
            break if core.nil?
            NxEngines::program0(core)
        }
    end

    # NxEngines::askAndThenGiveCoreToItemAttempt(item)
    def self.askAndThenGiveCoreToItemAttempt(item)
        if LucilleCore::askQuestionAnswerAsBoolean("> Add core ? ", false) then
            NxEngines::interactivelySetCoreAttempt(item)
        end
    end

    # NxEngines::interactivelySetCoreAttempt(item)
    def self.interactivelySetCoreAttempt(item)
        if item["mikuType"] == "NxEngine" then
            puts "You cannot give a core to a NxEngine"
            LucilleCore::pressEnterToContinue()
            return
        end
        core = NxEngines::interactivelySelectOneOrNull()
        return if core.nil?
        DarkEnergy::patch(item["uuid"], "parent", Tx8s::make(core["uuid"], rand))
    end
end





