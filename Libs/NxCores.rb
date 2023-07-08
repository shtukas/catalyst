
class NxCores

    # -----------------------------------------------
    # Build

    # NxCores::interactivelyMakeCoreOrNull()
    def self.interactivelyMakeCoreOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        return nil if description == ""
        engine = TxEngines::interactivelyMakeEngine()
        {
            "uuid"          => SecureRandom.uuid,
            "mikuType"      => "NxCore",
            "description"   => description,
            "engine"        => engine
        }
    end

    # -----------------------------------------------
    # Data

    # NxCores::toString(core)
    def self.toString(core)
        "✨ #{core["description"]} #{TxEngines::toString(core["engine"])}"
    end

    # NxCores::coreSuffix(item)
    def self.coreSuffix(item)
        parent = Tx8s::getParentOrNull(item)
        return "" if parent.nil?
        return "" if parent["mikuType"] != "NxCore"
        " (#{parent["description"].green})"
    end

    # NxCores::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        cores = DarkEnergy::mikuType("NxCore")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|core| NxCores::toString(core) })
    end

    # NxCores::interactivelyMakeTx8WithCoreParentOrNull()
    def self.interactivelyMakeTx8WithCoreParentOrNull()
        core = NxCores::interactivelySelectOneOrNull()
        position = Tx8s::interactivelyDecidePositionUnderThisParent(core)
        Tx8s::make(core["uuid"], position)
    end

    # NxCores::infinityuuid()
    def self.infinityuuid()
        "bc3901ad-18ad-4354-b90b-63f7a611e64e"
    end

    # NxCores::listingItems()
    def self.listingItems()
        return []
        DarkEnergy::mikuType("NxCores")
            .select{|core| TxEngines::compositeCompletionRatio(core["engine"]) < 1}
    end

    # -----------------------------------------------
    # Ops

    # NxCores::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("NxCore").each{|core|
            engine = TxEngines::engine_maintenance(core["description"], core["engine"])
            next if engine.nil?
            DarkEnergy::patch(core["uuid"], "engine", engine)
        }
    end

    # NxCores::maintenance2()
    def self.maintenance2()
        padding = ([0] + DarkEnergy::mikuType("NxCore").map{|core| core["description"].size}).max
        XCache::set("e8f9022e-3a5d-4e3b-87e0-809a3308b8ad", padding)
    end

    # NxCores::itemToStringListing(store, item)
    def self.itemToStringListing(store, item)
        return nil if item.nil?
        storePrefix = store ? "(#{store.prefixString()})" : "     "

        str1 = nil
        if item["mikuType"] == "NxTask" then
            str1 = NxTasks::toStringForCoreListing(item)
        end
        if item["mikuType"] == "NxPage" then
            str1 = NxPages::toStringForCoreListing(item)
        end
        if item["mikuType"] == "NxCollection" then
            str1 = NxCollections::toStringForCoreListing(item)
        end
        if str1.nil? then
            str1 = PolyFunctions::toString(item)
        end

        engineSuffixForTasks = item["engine"] ? " #{TxEngines::toString(item["engine"])}" : ""

        line = "#{storePrefix} #{str1}#{NxBalls::nxballSuffixStatusIfRelevant(item)}#{DxNotes::toStringSuffix(item)}#{DoNotShowUntil::suffixString(item)}#{TmpSkip1::skipSuffix(item)}#{engineSuffixForTasks}#{TxDeadline::deadlineSuffix(item)}"

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

    # NxCores::program1(core)
    def self.program1(core)
        loop {

            core = DarkEnergy::itemOrNull(core["uuid"])
            return if core.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            store.register(core, false)
            spacecontrol.putsline NxCores::itemToStringListing(store, core)

            spacecontrol.putsline ""
            items = Tx8s::childrenInOrder(core)

            # ------------------------------------------------------------------
            # position corretion
            if Config::isPrimaryInstance() and items.size > 0 and items[0]["parent"]["position"] <= -10 then
                items = items.map{|item|
                    item["parent"]["position"] = item["parent"]["position"] + 10
                    DarkEnergy::commit(item)
                    item
                }
            end
            # ------------------------------------------------------------------

            waves, items = items.partition{|item| item["mikuType"] == "Wave" }
            pages, items = items.partition{|item| item["mikuType"] == "NxPage" }
            collections, items = items.partition{|item| item["mikuType"] == "NxCollection" }

            pages = pages.sort_by{|item| item["unixtime"] }
            collections = collections.sort_by{|item| item["unixtime"] }

            (waves + pages + collections + items)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline NxCores::itemToStringListing(store, item)
                    break if !status
                }

            puts ""
            puts "(top, pile, task, page, collection, position *, move * to *, mush *)"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "top" then
                NxTasks::interactivelyIssueNewAtTopAtParentOrNull(core)
                next
            end

            if input == "task" then
                NxTasks::interactivelyIssueNewAtParentOrNull(core)
                next
            end

            if input == "pile" then
                Tx8s::pileAtThisParent(core)
            end

            if input == "page" then
                NxPages::interactivelyIssueNewAtParentOrNull(core)
                next
            end

            if input == "collection" then
                NxCollections::interactivelyIssueNewAtParentOrNull(core)
                next
            end

            if input.start_with?("position") then
                itemindex = input[8, input.length].strip.to_i
                item = store.get(itemindex)
                return if item.nil?
                Tx8s::repositionItemAtSameParent(item)
                next
            end

            if input.start_with?("move") then
                input = input[4, input.length].strip
                i1, i2 = input.split("to").map{|t| t.strip.to_i }
                item = store.get(i1)
                return if item.nil?
                newparent = store.get(i2)
                return if newparent.nil?
                puts "moving: #{PolyFunctions::toString(item)}"
                puts "to    : #{PolyFunctions::toString(newparent)}"
                Tx8s::interactivelyPlaceItemAtParentAttempt(item, newparent)
                next
            end

            if input.start_with?("mush") then
                itemindex = input[4, input.length].strip.to_i
                item = store.get(itemindex)
                return if item.nil?
                needs = LucilleCore::askQuestionAnswerAsString("needs in hours: ").to_f
                DxAntimatters::issue(item["uuid"], needs*3600)
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxCores::program2()
    def self.program2()
        loop {
            hours = DarkEnergy::mikuType("NxCore").map{|core| core["engine"]["hours"]}.inject(0, :+)
            puts "total hours: #{hours}; #{(hours.to_f/7).round(2)} hours/day"
            cores = DarkEnergy::mikuType("NxCore").sort_by{|item| item["description"] }
            core = LucilleCore::selectEntityFromListOfEntitiesOrNull("core", cores, lambda{|core| NxCores::toString(core) })
            return if core.nil?
            NxCores::program1(core)
        }
    end
end
