
class TxCores

    # -----------------------------------------------
    # Build

    # TxCores::interactivelyMakeCoreOrNull()
    def self.interactivelyMakeCoreOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("weekly hours (empty for abort): ")
        return nil if hours == ""
        return nil if hours == "0"
        {
            "uuid"          => SecureRandom.uuid,
            "mikuType"      => "TxCore",
            "description"   => description,
            "hours"         => hours.to_f,
            "lastResetTime" => Time.new.to_f,
            "capsule"       => SecureRandom.hex
        }
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
        padding = XCache::getOrDefaultValue("e8f9022e-3a5d-4e3b-87e0-809a3308b8ad", "0").to_i
        strings = []

        strings << "⏱️  #{core["description"].ljust(padding)} (core: today: #{"#{"%6.2f" % (100*TxCores::dayCompletionRatio(core))}%".green} of #{"%5.2f" % (core["hours"].to_f/5)} hours"
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

        strings << ")"
        strings.join()
    end

    # TxCores::coreSuffix(item)
    def self.coreSuffix(item)
        parent = Tx8s::getParentOrNull(item)
        return "" if parent.nil?
        return "" if parent["mikuType"] != "TxCore"
        " (#{parent["description"].green})"
    end

    # TxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        cores = DarkEnergy::mikuType("TxCore")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|core| TxCores::toString(core) })
    end

    # TxCores::interactivelyMakeTx8WithCoreParentOrNull()
    def self.interactivelyMakeTx8WithCoreParentOrNull()
        core = TxCores::interactivelySelectOneOrNull()
        position = Tx8s::interactivelyDecidePositionUnderThisParent(core)
        Tx8s::make(core["uuid"], position)
    end

    # TxCores::todayNeedsInHours(core)
    def self.todayNeedsInHours(core)
        core["hours"].to_f/5 - Bank::getValueAtDate(core["uuid"], CommonUtils::today()).to_f/3600
    end

    # -----------------------------------------------
    # Ops

    # TxCores::core_maintenance(core)
    def self.core_maintenance(core)
        return nil if Bank::getValue(core["capsule"]).to_f/3600 < core["hours"]
        return nil if (Time.new.to_i - core["lastResetTime"]) < 86400*7
        puts "> I am about to reset core: #{core["description"]}"
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

    # TxCores::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("TxCore").each{|core|
            core = TxCores::core_maintenance(core)
            next if core.nil?
            DarkEnergy::commit(core)
        }
    end

    # TxCores::maintenance2()
    def self.maintenance2()
        padding = ([0] + DarkEnergy::mikuType("TxCore").map{|core| core["description"].size}).max
        XCache::set("e8f9022e-3a5d-4e3b-87e0-809a3308b8ad", padding)
    end

    # TxCores::maintenance3()
    def self.maintenance3()
        DarkEnergy::mikuType("TxCore")
            .each{|core|
                next if !DoNotShowUntil::isVisible(core)
                next if Bank::getValue(core["capsule"]).to_f >= core["hours"]*3600
                next if Time.new.wday == 0 # not on sundays
                next if DxAntimatters::familySampleNegativeNonRunningOrNull(core["uuid"])
                todayNeedsInHours = TxCores::todayNeedsInHours(core)
                next if todayNeedsInHours < 0
                puts "anti-matter creation: #{core["description"]}, #{todayNeedsInHours.round(2)} hours".green
                4.times {
                    PolyActions::addTimeToItem(core, 0.25*1.01*todayNeedsInHours*3600) # adding time to the core
                    antimatter = DxAntimatters::issue(core["uuid"], core["description"], -0.25*1.01*todayNeedsInHours*3600) # making an anti-matter with opposite value
                    puts JSON.pretty_generate(antimatter)
                    ListingPositions::set(antimatter, ListingPositions::randomPositionInLateRange())
                }
            }
    end

    # TxCores::itemToStringListing(store, item)
    def self.itemToStringListing(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        str1 = PolyFunctions::toString(item)

        ordinalSuffix = (item["mikuType"] == "NxTask" and ListingPositions::getOrNull(item)) ? " (#{"%5.2f" % ListingPositions::getOrNull(item)})" : ""

        line = "#{storePrefix}#{ordinalSuffix} #{str1}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{NxNotes::toStringSuffix(item)}#{DoNotShowUntil::suffixString(item)}#{TmpSkip1::skipSuffix(item)}"

        if !DoNotShowUntil::isVisible(item) and !NxBalls::itemIsActive(item) then
            line = line.yellow
        end

        if TmpSkip1::isSkipped(item) then
            line = line.yellow
        end

        if NxBalls::itemIsActive(item) then
            line = line.green
        end

        line
    end

    # TxCores::program1(core)
    def self.program1(core)
        loop {

            core = DarkEnergy::itemOrNull(core["uuid"])
            return if core.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            store.register(core, false)
            spacecontrol.putsline TxCores::itemToStringListing(store, core)

            spacecontrol.putsline ""
            items = Tx8s::childrenInOrder(core)
            waves, items = items.partition{|item| item["mikuType"] == "Wave" }
            projects, items = items.partition{|item| item["mikuType"] == "NxProject" }

            (waves + projects + items)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline TxCores::itemToStringListing(store, item)
                    break if !status
                }

            puts ""
            puts "(task, pile, project)"
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

            if input == "project" then
                NxProjects::interactivelyIssueNewAtParentOrNull(core)
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # TxCores::program2()
    def self.program2()
        loop {
            hours = DarkEnergy::mikuType("TxCore").map{|core| core["hours"]}.inject(0, :+)
            puts "total hours: #{hours}; #{(hours.to_f/7).round(2)} hours/day"
            cores = DarkEnergy::mikuType("TxCore").sort_by{|item| item["description"] }
            core = LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|core| TxCores::toString(core) })
            return if core.nil?
            TxCores::program1(core)
        }
    end
end
