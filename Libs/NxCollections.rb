
class NxCollections

    # NxCollections::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        engine = TxEngines::interactivelyMakeEngine()
        DarkEnergy::init("NxCollection", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "engine", engine)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxCollections::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        tx8 = Tx8s::make(parent["uuid"], 0)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        engine = TxEngines::interactivelyMakeEngine()
        DarkEnergy::init("NxCollection", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "engine", engine)
        DarkEnergy::patch(uuid, "parent", tx8)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxCollections::toString(item)
    def self.toString(item)
        "🫧 #{item["description"]}#{NxCores::coreSuffix(item)} #{TxEngines::toString(item["engine"])}"
    end

    # NxCollections::toStringForMainListing(item)
    def self.toStringForMainListing(item)
        "🫧 #{item["description"]}#{NxCores::coreSuffix(item)} #{TxEngines::toString(item["engine"])}"
    end

    # NxCollections::toStringForCoreListing(item)
    def self.toStringForCoreListing(item)
        "🫧 #{item["description"]} #{TxEngines::toString(item["engine"])}"
    end

    # NxCollections::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxCollection")
            .select{|project| TxEngines::compositeCompletionRatio(project["engine"]) < 1 }
    end

    # NxCollections::maintenance()
    def self.maintenance()
        # Ensuring consistency of parenting targets
        DarkEnergy::mikuType("NxCollection").each{|item|
            next if item["parent"].nil?
            if DarkEnergy::itemOrNull(item["parent"]["uuid"]).nil? then
                DarkEnergy::patch(uuid, "parent", nil)
            end
        }

        # Move orphan item to Infinity
        DarkEnergy::mikuType("NxCollection").each{|item|
            next if item["parent"]
            parent = DarkEnergy::itemOrNull(NxCores::infinityuuid())
            item["parent"] = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))
            DarkEnergy::commit(item)
        }

        DarkEnergy::mikuType("TxCollection").each{|item|
            engine = item["engine"]
            engine = TxEngines::engine_maintenance(engine)
            next if engine.nil?
            DarkEnergy::patch(item["uuid"], "engine", engine)
        }
    end

    # NxCollections::program1(collection)
    def self.program1(collection)
        loop {

            collection = DarkEnergy::itemOrNull(collection["uuid"])
            return if collection.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            store.register(collection, false)
            spacecontrol.putsline NxCores::itemToStringListing(store, collection)

            spacecontrol.putsline ""
            items = Tx8s::childrenInOrder(collection)

            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline NxCores::itemToStringListing(store, item)
                    break if !status
                }

            puts ""
            puts "(task, pile, position *, mush *)"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                NxTasks::interactivelyIssueNewAtParentOrNull(collection)
                next
            end

            if input == "pile" then
                Tx8s::pileAtThisParent(collection)
            end

            if input.start_with?("position") then
                itemindex = input[8, input.length].strip.to_i
                item = store.get(itemindex)
                return if item.nil?
                Tx8s::repositionItemAtSameParent(item)
                next
            end

            if input.start_with?("mush") then
                itemindex = input[4, input.length].strip.to_i
                item = store.get(itemindex)
                return if item.nil?
                needs = LucilleCore::askQuestionAnswerAsString("needs in hours: ").to_f
                DxAntimatters::issue(item["uuid"], needs)
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxCollections::completionRatio(collection)
    def self.completionRatio(collection)
        TxEngines::compositeCompletionRatio(collection["engine"])
    end
end
