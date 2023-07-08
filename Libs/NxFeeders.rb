
class NxFeeders

    # --------------------------------------------------------------------------
    # Builders

    # NxFeeders::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        engine = TxEngines::interactivelyMakeEngine()
        DarkEnergy::init("NxFeeder", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "engine", engine)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxFeeders::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        tx8 = Tx8s::make(parent["uuid"], 0)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        engine = TxEngines::interactivelyMakeEngine()
        DarkEnergy::init("NxFeeder", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "engine", engine)
        DarkEnergy::patch(uuid, "parent", tx8)
        DarkEnergy::itemOrNull(uuid)
    end

    # --------------------------------------------------------------------------
    # Data

    # NxFeeders::toString(item)
    def self.toString(item)
        "🐬 #{item["description"]}"
    end

    # NxFeeders::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxFeeder")
            #.select{|feeder| TxEngines::compositeCompletionRatio(feeder["engine"]) < 1 }
    end

    # NxFeeders::completionRatio(feeder)
    def self.completionRatio(feeder)
        TxEngines::compositeCompletionRatio(feeder["engine"])
    end

    # NxFeeders::infinityuuid()
    def self.infinityuuid()
        "bc3901ad-18ad-4354-b90b-63f7a611e64e"
    end

    # NxFeeders::interactivelySelectOrNull()
    def self.interactivelySelectOrNull()
        feeders = DarkEnergy::mikuType("NxFeeder")
        padding = feeders.map{|item| NxFeeders::toString(item).size }.max
        LucilleCore::selectEntityFromListOfEntitiesOrNull("feeder", feeders, lambda{|item| "#{NxFeeders::toString(item).ljust(padding)} #{TxDrivers::suffix(item)}" })
    end

    # --------------------------------------------------------------------------
    # Ops

    # NxFeeders::maintenance()
    def self.maintenance()
        # Ensuring consistency of parenting targets
        DarkEnergy::mikuType("NxTask").each{|item|
            next if item["parent"].nil?
            if DarkEnergy::itemOrNull(item["parent"]["uuid"]).nil? then
                DarkEnergy::patch(uuid, "parent", nil)
            end
        }

        # Move orphan items to Infinity
        DarkEnergy::mikuType("NxTask").each{|item|
            next if item["parent"]
            parent = DarkEnergy::itemOrNull(NxFeeders::infinityuuid())
            item["parent"] = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))
            DarkEnergy::commit(item)
        }
    end

    # NxFeeders::program1(feeder)
    def self.program1(feeder)
        loop {

            feeder = DarkEnergy::itemOrNull(feeder["uuid"])
            return if feeder.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            store.register(feeder, false)
            spacecontrol.putsline Listing::toString2(store, feeder)

            spacecontrol.putsline ""
            items = Tx8s::childrenInOrder(feeder)

            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    status = spacecontrol.putsline Listing::toString2(store, item)
                    break if !status
                }

            puts ""
            puts "(task, pile, position *)"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                NxTasks::interactivelyIssueNewAtParentOrNull(feeder)
                next
            end

            if input == "pile" then
                Tx8s::pileAtThisParent(feeder)
            end

            if input.start_with?("position") then
                itemindex = input[8, input.length].strip.to_i
                item = store.get(itemindex)
                return if item.nil?
                Tx8s::repositionItemAtSameParent(item)
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxFeeders::program2()
    def self.program2()
        loop {
            feeder = NxFeeders::interactivelySelectOrNull()
            break if feeder.nil?
            NxFeeders::program1(feeder)
        }
    end
end
