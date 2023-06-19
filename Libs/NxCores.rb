
class NxCores

        # -------------------------

    # NxCores::grid1uuid()
    def self.grid1uuid()
        "df40842a-f439-40d2-a274-bb8526a40189"
    end

    # NxCores::grid1()
    def self.grid1()
        core = DarkEnergy::itemOrNull(NxCores::grid1uuid())
        if core.nil? then
            raise "(error: f844acd4-b819-4442-9bdb-340befa1804c) could not find infinity core"
        end
        core
    end

    # NxCores::grid1children()
    def self.grid1children()
        DarkEnergy::mikuType("NxTask")
            .select{|task| task["core"].nil? }
            .sort_by{|task| task["unixtime"] }
            .first(NxCores::infinityDepth())
    end

    # NxCores::grid1children_ordered_uuids()
    def self.grid1children_ordered_uuids()
        NxCores::grid1children().map{|item| item["uuid"] }
    end

    # NxCores::item_belongs_to_grid1(item)
    def self.item_belongs_to_grid1(item)
        NxCores::grid1children_ordered_uuids().include?(item["uuid"])
    end

    # -------------------------

    # NxCores::grid2uuid()
    def self.grid2uuid()
        "f96cc544-06ef-4e30-b415-e57e78eb3d73"
    end

    # NxCores::grid2()
    def self.grid2()
        core = DarkEnergy::itemOrNull(NxCores::grid2uuid())
        if core.nil? then
            raise "(error: 7320289f-10c4-49c9-8f50-1f5fa22fcb5a) could not find reverse infinity core"
        end
        core
    end
 
    # NxCores::grid2children()
    def self.grid2children()
        DarkEnergy::mikuType("NxTask")
            .select{|task| task["core"].nil? }
            .sort_by{|task| task["unixtime"] }
            .reverse
            .first(NxCores::infinityDepth())
    end

    # NxCores::grid2children_ordered_uuids()
    def self.grid2children_ordered_uuids()
        NxCores::grid2children().map{|item| item["uuid"] }
    end

    # NxCores::item_belongs_to_grid2(item)
    def self.item_belongs_to_grid2(item)
        NxCores::grid2children_ordered_uuids().include?(item["uuid"])
    end

    # -------------------------

    # NxCores::infinityDepth()
    def self.infinityDepth()
        100
    end

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
        hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
        return nil if hours == ""
        hours = hours.to_f
        if hours == 0 then
            puts "hours cannot be zero"
            LucilleCore::pressEnterToContinue()
            return NxCores::interactivelyIssueNewOrNull()
        end
        core = NxCores::makeCore(uuid, description, hours)
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

    # NxCores::toString(core)
    def self.toString(core)
        padding = XCache::getOrDefaultValue("0e067f3e-a954-4138-8336-876240b9b7dd", "0").to_i
        strings = []

        strings << "☕️ #{core["description"].ljust(padding)} (core: today: #{"#{"%6.2f" % (100*NxCores::dayCompletionRatio(core))}%".green} of #{"%5.2f" % (core["hours"].to_f/5)} hours"
        strings << ", period: #{"#{"%6.2f" % (100*NxCores::periodCompletionRatio(core))}%".green} of #{"%5.2f" % core["hours"]} hours"

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

    # NxCores::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxCore")
            .select{|core| NxCores::listingCompletionRatio(core) < 1 }
            .sort_by{|core| NxCores::listingCompletionRatio(core) }
    end

    # NxCores::children(core)
    def self.children(core)
        if core["uuid"] == NxCores::grid1uuid() then
            return NxCores::grid1children()
        end
        if core["uuid"] == NxCores::grid2uuid() then
            return NxCores::grid2children()
        end

        items = DarkEnergy::all()
                    .select{|item| item["mikuType"] != "NxDeadline" }
                    .select{|item| item["core"] == core["uuid"] }

        burners, items = items.partition{|item| item["mikuType"] == "NxBurner" }
        ondates, items = items.partition{|item| item["mikuType"] == "NxOndate" }
        waves,   items = items.partition{|item| item["mikuType"] == "Wave" }
        threads, items = items.partition{|item| item["mikuType"] == "NxThread" }
        tasks,  things = items.partition{|item| item["mikuType"] == "NxTask" }

        threads = threads.sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
        tasks = tasks.sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }

        things + burners + ondates + waves + threads + tasks
     end

    # NxCores::getItemCoreOrNull(item)
    def self.getItemCoreOrNull(item)
        return nil if item["core"].nil?
        DarkEnergy::itemOrNull(item["core"])
    end

    # NxCores::suffix(item)
    def self.suffix(item)
        core = NxCores::getItemCoreOrNull(item)
        return "" if core.nil?
        " (☕️ #{core["description"]})".green
    end

    # -------------------------
    # Ops

    # NxCores::maintenance_all_instances()
    def self.maintenance_all_instances()
        padding = DarkEnergy::mikuType("NxCore").map{|core| core["description"].size }.max
        XCache::set("0e067f3e-a954-4138-8336-876240b9b7dd", padding)
    end

    # NxCores::maintenance_leader_instance()
    def self.maintenance_leader_instance()
        DarkEnergy::mikuType("NxCore").each{|core| Mechanics::engine_maintenance(core) }
    end

    # NxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        cores = DarkEnergy::mikuType("NxCore")
                    .reject{|core| core["uuid"] == NxCores::grid1uuid() }
                    .reject{|core| core["uuid"] == NxCores::grid2uuid() }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|item| item["description"] })
    end

    # NxCores::program0(core)
    def self.program0(core)
        loop {

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            puts ""
            spacecontrol.putsline "@core:"
            store.register(core, false)
            spacecontrol.putsline Listing::itemToListingLine(store, core)

            items = NxCores::children(core)

            Listing::printing(spacecontrol, store, items)

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxCores::program()
    def self.program()
        loop {
            cores = DarkEnergy::mikuType("NxCore").sort_by{|core| NxCores::listingCompletionRatio(core) }
            core = LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|core| NxCores::toString(core) })
            break if core.nil?
            NxCores::program0(core)
        }
    end

    # NxCores::askAndThenGiveCoreToItemAttempt(item)
    def self.askAndThenGiveCoreToItemAttempt(item)
        if LucilleCore::askQuestionAnswerAsBoolean("> Add core ? ", false) then
            NxCores::interactivelySetCore(item)
        end
    end

    # NxCores::interactivelySetCore(item)
    def self.interactivelySetCore(item)
        if item["mikuType"] == "NxCore" then
            puts "You cannot give a core to a NxCore"
            LucilleCore::pressEnterToContinue()
            return
        end
        core = NxCores::interactivelySelectOneOrNull()
        return if core.nil?
        DarkEnergy::patch(item["uuid"], "core", core["uuid"])
    end

    # NxCores::askAndThenSetCoreAttempt(item)
    def self.askAndThenSetCoreAttempt(item)
        return if !LucilleCore::askQuestionAnswerAsBoolean("> set core ? ")
        NxCores::interactivelySetCore(item)
    end
end





