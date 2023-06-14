
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

    # NxCores::grid1childrenInPositionOrder()
    def self.grid1childrenInPositionOrder()
        DarkEnergy::mikuType("NxTask")
            .select{|task| (parent = Parenting::getParentOrNull(task)).nil? or (parent["uuid"] == NxCores::grid1uuid()) }
            .sort_by{|task| task["unixtime"] }
            .first(NxCores::infinityDepth())
    end

    # NxCores::grid1children_ordered_uuids()
    def self.grid1children_ordered_uuids()
        NxCores::grid1childrenInPositionOrder().map{|item| item["uuid"] }
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
 
    # NxCores::grid2childrenInPositionOrder()
    def self.grid2childrenInPositionOrder()
        DarkEnergy::mikuType("NxTask")
            .select{|task| (parent = Parenting::getParentOrNull(task)).nil? or (parent["uuid"] == NxCores::grid2uuid()) }
            .sort_by{|task| task["unixtime"] }
            .reverse
            .first(NxCores::infinityDepth())
    end

    # NxCores::grid2children_ordered_uuids()
    def self.grid2children_ordered_uuids()
        NxCores::grid2childrenInPositionOrder().map{|item| item["uuid"] }
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
        hours = LucilleCore::askQuestionAnswerAsString("hours: ")
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

    # NxCores::childrenInPositionOrder(core)
    def self.childrenInPositionOrder(core)
        if core["uuid"] == NxCores::grid1uuid() then
            return NxCores::grid1childrenInPositionOrder()
        end
        if core["uuid"] == NxCores::grid2uuid() then
            return NxCores::grid2childrenInPositionOrder()
        end
        Parenting::childrenInPositionOrder(core)
    end

    # -------------------------
    # Ops

    # NxCores::maintenance_one_core(core)
    def self.maintenance_one_core(core)
        return nil if Bank::getValue(core["capsule"]).to_f/3600 < core["hours"]
        return nil if (Time.new.to_i - core["lastResetTime"]) < 86400*7
        puts "> I am about to reset core: #{NxCores::toString(core)}"
        LucilleCore::pressEnterToContinue()
        Bank::reset(core["capsule"])
        if !LucilleCore::askQuestionAnswerAsBoolean("> continue with #{core["hours"]} hours ? ") then
            hours = LucilleCore::askQuestionAnswerAsString("specify period load in hours (empty for the current value): ")
            if hours.size > 0 then
                core["hours"] = hours.to_f
            end
        end
        core["lastResetTime"] = Time.new.to_i
        DarkEnergy::commit(core)
    end

    # NxCores::maintenance_all_instances()
    def self.maintenance_all_instances()
        padding = DarkEnergy::mikuType("NxCore").map{|core| core["description"].size }.max
        XCache::set("0e067f3e-a954-4138-8336-876240b9b7dd", padding)
    end

    # NxCores::maintenance_leader_instance()
    def self.maintenance_leader_instance()
        DarkEnergy::mikuType("NxCore").each{|core| NxCores::maintenance_one_core(core) }
    end

    # NxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        cores = DarkEnergy::mikuType("NxCore")
                    .reject{|core| core["uuid"] == NxCores::grid1uuid() }
                    .reject{|core| core["uuid"] == NxCores::grid2uuid() }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|item| item["description"] })
    end

    # NxCores::interactivelySelectOneUUIDOrNull()
    def self.interactivelySelectOneUUIDOrNull()
        core = NxCores::interactivelySelectOneOrNull()
        return nil if core.nil?
        core
    end

    # NxCores::program0(core)
    def self.program0(core)
        loop {

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            puts ""
            store.register(core, false)
            spacecontrol.putsline Listing::itemToListingLine(store, core)

            items = NxCores::childrenInPositionOrder(core)

            Listing::printing(spacecontrol, store, items)

            puts ""
            puts ".. (<n>) | task | pool | stack | destroy"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                child = NxTasks::interactivelyMakeOrNull()
                next if child.nil?
                puts JSON.pretty_generate(child)
                position = Parenting::interactivelyDecideRelevantPositionAtParent(core)
                DarkEnergy::commit(child) # commiting the child after deciding a position
                Parenting::set_objects(core, child, position) # setting relationship after (!) the two objects are written
                next
            end
            if input == "pool" then
                child = TxPools::interactivelyMakeOrNull()
                next if child.nil?
                puts JSON.pretty_generate(child)
                position = Parenting::interactivelyDecideRelevantPositionAtParent(core)
                DarkEnergy::commit(child) # commiting the child after deciding a position
                Parenting::set_objects(core, child, position) # setting relationship after (!) the two objects are written
                next
            end
            if input == "stack" then
                child = TxStacks::interactivelyMakeOrNull()
                next if child.nil?
                puts JSON.pretty_generate(child)
                position = Parenting::interactivelyDecideRelevantPositionAtParent(core)
                DarkEnergy::commit(child) # commiting the child after deciding a position
                Parenting::set_objects(core, child, position) # setting relationship after (!) the two objects are written
                next
            end
            if input == "destroy" then
                if items.empty? then
                    if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction: ") then
                        DarkEnergy::destroy(core["uuid"])
                    end
                else
                    puts "Collection needs to be empty to be destroyed"
                    LucilleCore::pressEnterToContinue()
                end
                next
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end

    # NxCores::program1(core)
    def self.program1(core)
        loop {
            core = DarkEnergy::itemOrNull(core["uuid"])
            return if core.nil?
            actions = ["program (default)", "add time", "rename"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
            if action == "program (default)" or action.nil? then
                NxCores::program0(core)
                return
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                PolyActions::addTimeToItem(core, timeInHours*3600)
            end
            if action == "rename" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                next if description == ""
                DarkEnergy::patch(core["uuid"], "description", description)
            end
        }
    end

    # NxCores::program()
    def self.program()
        loop {
            cores = DarkEnergy::mikuType("NxCore").sort_by{|core| NxCores::listingCompletionRatio(core) }
            core = LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|core| NxCores::toString(core) })
            break if core.nil?
            NxCores::program1(core)
        }
    end

    # NxCores::giveCoreToItemAttempt(item)
    def self.giveCoreToItemAttempt(item)
        if item["mikuType"] == "NxCore" then
            puts "You cannot give a core to a NxCore"
            LucilleCore::pressEnterToContinue()
            return
        end
        core = NxCores::interactivelySelectOneOrNull()
        return if core.nil?
        position = rand
        Parenting::set_objects(core, item, position)
    end

    # NxCores::interactivelySelectPositionAmongTop(core)
    def self.interactivelySelectPositionAmongTop(core)
        Parenting::childrenInPositionOrder(core).first(30).each{|item|
            puts NxTasks::toString(item)
        }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            (Parenting::childrenPositions(core) + [0]).max + 1
        else
            position.to_f
        end
    end

    # NxCores::interactivelyDecideCoreAndSetAsParentIfNotAlreadySet(item)
    def self.interactivelyDecideCoreAndSetAsParentIfNotAlreadySet(item)
        return if Parenting::getParentOrNull(item)
        core = NxCores::interactivelySelectOneOrNull()
        return if core.nil?
        position = NxCores::interactivelySelectPositionAmongTop(core)
        Parenting::set_uuids(core["uuid"], item["uuid"], position)
    end

    # NxCores::interactivelyDecideCoreAndSetAsParent(itemuuid)
    def self.interactivelyDecideCoreAndSetAsParent(itemuuid)
        core = NxCores::interactivelySelectOneOrNull()
        return if core.nil?
        position = NxCores::interactivelySelectPositionAmongTop(core)
        Parenting::set_uuids(core["uuid"], itemuuid, position)
    end

    # NxCores::coreSuffix(item)
    def self.coreSuffix(item)
        parent = Parenting::getParentOrNull(item)
        return nil if parent.nil?
        return nil if parent["mikuType"] != "NxCore"
        " (#{parent["description"]})".green
    end
end





