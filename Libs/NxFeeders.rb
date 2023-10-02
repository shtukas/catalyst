

class NxFeeders

    # --------------------------------------------------
    # Makers

    # NxFeeders::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        Events::publishItemInit("NxFeeder", uuid)

        engine = TxEngine::interactivelyIssueNew()

        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Events::publishItemAttributeUpdate(uuid, "global-position", Catalyst::newGlobalLastPosition())
        Events::publishItemAttributeUpdate(uuid, "engine-2251", engine)
        Catalyst::itemOrNull(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxFeeders::toString(item)
    def self.toString(item)
        count = NxFeeders::elementsInOrder(item).size
        s1 = (count > 0) ? "(#{count.to_s.rjust(3)})" : "     "
        "▫️  #{s1} #{TxEngine::prefix(item)}#{item["description"]}#{TxCores::suffix(item)}"
    end

    # NxFeeders::feedersInPriorityOrder()
    def self.feedersInPriorityOrder()
        Catalyst::mikuType("NxFeeder").sort_by{|item| TxEngine::ratio(item["engine-2251"]) }
    end

    # NxFeeders::elementsInOrder(feeder)
    def self.elementsInOrder(feeder)
        Catalyst::mikuType("NxTask")
            .select{|item| item["engine-2251"] == feeder["uuid"] }
            .sort_by {|item| item["global-position"] }
    end

    # NxFeeders::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        cores = Catalyst::mikuType("NxFeeder")
                    .sort_by{|item| TxEngine::ratio(item["engine-2251"]) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("feeder", items, lambda{|item| TxCores::toString(item) })
    end

    # --------------------------------------------------
    # Operations

    # NxFeeders::append(feeder, task)
    def self.append(feeder, task)
        Events::publishItemAttributeUpdate(task["uuid"], "feeder-1509", feeder["uuid"])
    end

    # NxFeeders::program1(feeder)
    def self.program1(feeder)
        loop {

            feeder = Catalyst::itemOrNull(feeder["uuid"])
            return if feeder.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(feeder, false)
            puts  Listing::toString2(store, feeder)
            puts  ""

            NxFeeders::elementsInOrder(feeder)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            puts "task"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Events::publishItemAttributeUpdate(task["uuid"], "feeder-1509", feeder["uuid"])
                next
            end

            if Interpreting::match("sort", input) then
                items = NxFeeders::elementsInOrder(feeder)
                selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    Events::publishItemAttributeUpdate(item["uuid"], "global-position", Catalyst::newGlobalFirstPosition())
                }
                next
            end
            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxFeeders::program2()
    def self.program2()
        loop {
            feeder = NxFeeders::interactivelySelectOneOrNull()
            return if feeder.nil?
            NxFeeders::program1(feeder)
        }
    end
end
