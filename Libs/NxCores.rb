
class NxCores

    # NxCores::infinityuuid()
    def self.infinityuuid()
        "df40842a-f439-40d2-a274-bb8526a40189"
    end

    # NxCores::infinitycore()
    def self.infinitycore()
        core = DarkEnergy::itemOrNull(NxCores::infinityuuid())
        if core.nil? then
            raise "(error: f844acd4-b819-4442-9bdb-340befa1804c) could not find infinity core"
        end
        core
    end

    # NxCores::reverseinfinityuuid()
    def self.reverseinfinityuuid()
        "f96cc544-06ef-4e30-b415-e57e78eb3d73"
    end

    # NxCores::reverseinfinitycore()
    def self.reverseinfinitycore()
        core = DarkEnergy::itemOrNull(NxCores::reverseinfinityuuid())
        if core.nil? then
            raise "(error: 7320289f-10c4-49c9-8f50-1f5fa22fcb5a) could not find reverse infinity core"
        end
        core
    end

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

        strings << "☕️ #{core["description"].ljust(padding)} (core: today: #{"#{"%5.2f" % (100*NxCores::dayCompletionRatio(core))}%".green} of #{"%5.2f" % (core["hours"].to_f/5)} hours"
        strings << ", period: #{"#{"%5.2f" % (100*NxCores::periodCompletionRatio(core))}%".green} of #{"%5.2f" % core["hours"]} hours"

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

    # NxCores::children_ordered(core)
    def self.children_ordered(core)
        if core["uuid"] == NxCores::infinityuuid() then
            return Memoize::evaluate(
                "827d8bb1-1065-4727-b5d7-1db3cf9e5342", # infinity
                lambda { 
                    DarkEnergy::mikuType("NxTask")
                        .select{|task| (parent = Parenting::getParentOrNull(task)).nil? or (parent["uuid"] == NxCores::infinityuuid()) }
                        .sort_by{|task| task["unixtime"] }
                        .first(NxCores::infinityDepth())
                },
                86400
            )
        end
        if core["uuid"] == NxCores::reverseinfinityuuid() then
            return Memoize::evaluate(
                "2f8cd125-6309-4e36-bef6-ea08580d824e",
                lambda { 
                    DarkEnergy::mikuType("NxTask")
                        .select{|task| (parent = Parenting::getParentOrNull(task)).nil? or (parent["uuid"] == NxCores::reverseinfinityuuid()) }
                        .sort_by{|task| task["unixtime"] }
                        .reverse
                        .first(NxCores::infinityDepth())
                },
                86400
            )
        end
        Parenting::children_ordered(core)
    end

    # NxCores::infinity_uuids()
    def self.infinity_uuids()
        core = NxCores::infinitycore()
        NxCores::children_ordered(core).map{|item| item["uuid"] }
    end

    # NxCores::reverseinfinity_uuids()
    def self.reverseinfinity_uuids()
        core = NxCores::reverseinfinitycore()
        NxCores::children_ordered(core).map{|item| item["uuid"] }
    end

    # -------------------------
    # Ops

    # NxCores::maintenance_one_core(core)
    def self.maintenance_one_core(core)
        return nil if Bank::getValue(core["capsule"]).to_f/3600 < core["hours"]
        return nil if (Time.new.to_i - core["lastResetTime"]) < 86400*7
        if Bank::getValue(core["capsule"]).to_f/3600 > 1.5*core["hours"] then
            overflow = 0.5*core["hours"]*3600
            puts "I am about to smooth core #{NxCores::toString(core)}, overflow: #{(overflow.to_f/3600).round(2)} hours for core: #{core["description"]}"
            LucilleCore::pressEnterToContinue()
            NxTimePromises::issue_things(core, overflow, 20)
            return nil
        end
        puts "> I am about to reset core: #{NxCores::toString(core)}"
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
                    .reject{|core| core["uuid"] == NxCores::infinityuuid() }
                    .reject{|core| core["uuid"] == NxCores::reverseinfinityuuid() }
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

            Listing::printing(
                spacecontrol,
                store, 
                [], # times
                [], # cores display
                [], # engines display
                Listing::burnersAndFires().select{|item| Parenting::isParentChild(core, item)},
                NxCores::children_ordered(core)
            )

            puts ""
            puts ".. (<n>) | child"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "child" then
                Parenting::interactivelyIssueChildOrNothing(core)
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
            core = LucilleCore::selectEntityFromListOfEntitiesOrNull("core", DarkEnergy::mikuType("NxCore"), lambda{|core| NxCores::toString(core) })
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
        position = NxCores::interactivelySelectPositionAmongTop(core)
        Parenting::set_objects(core, item, position)
    end

    # NxCores::interactivelySelectPositionAmongTop(core)
    def self.interactivelySelectPositionAmongTop(core)
        Parenting::children_ordered(core).first(30).each{|item|
            puts NxTasks::toString(item)
        }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            (Parenting::childrenPositions(core) + [0]).max + 1
        else
            position.to_f
        end
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





