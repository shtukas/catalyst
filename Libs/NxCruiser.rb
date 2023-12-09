
class NxCruisers

    # NxCruisers::issueWithInit(uuid, description, engine, coredataReference)
    def self.issueWithInit(uuid, description, engine, coredataReference)
        DataCenter::itemInit(uuid, "NxCruiser")
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "engine", engine)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "field11", coredataReference)
        DataCenter::itemOrNull(uuid)
    end

    # NxCruisers::issueWithoutInit(uuid, description, engine, coredataReference)
    def self.issueWithoutInit(uuid, description, engine, coredataReference)
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "engine", engine)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "field11", coredataReference)
        DataCenter::itemOrNull(uuid)
    end

    # NxCruisers::interactivelyIssueNewOrNull2(uuid)
    def self.interactivelyIssueNewOrNull2(uuid)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        engine = TxCores::interactivelyMakeNewOrNull()
        return if engine.nil?
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        NxCruisers::issueWithInit(uuid, description, engine, coredataref)
    end

    # NxCruisers::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        NxCruisers::interactivelyIssueNewOrNull2(uuid)
    end

    # ------------------
    # Data

    # NxCruisers::toString(item)
    def self.toString(item)
        if item["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            count = LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataHub/Buffer-In").select{|location| !File.basename(location).start_with?(".") }
            if count then
                return "⛵️ #{TxCores::string1(item["engine"])} special circusmtances: DataHub/Buffer-In #{TxCores::string2(item["engine"]).yellow}#{CoreDataRefStrings::itemToSuffixString(item).red}"
            end
        end
        "⛵️ #{TxCores::string1(item["engine"])} #{item["description"]} #{TxCores::string2(item["engine"]).yellow}#{CoreDataRefStrings::itemToSuffixString(item).red}"
    end

    # NxCruisers::listingItems()
    def self.listingItems()
        DataCenter::mikuType("NxCruiser")
    end

    # NxCruisers::stack(item)
    def self.stack(item)
        if item["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            return DataCenter::mikuType("NxTask")
                    .select{|item| item["stackuuid"].nil? or DataCenter::itemOrNull(item["stackuuid"]).nil? }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        DataCenter::mikuType("NxTask")
            .select{|item| item["stackuuid"] == item["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxCruisers::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = DataCenter::mikuType("NxCruiser")
                    .sort_by{|item| TxCores::coreDayCompletionRatio(item["engine"]) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("ship", items, lambda{|item| NxCruisers::toString(item) })
    end

    # NxCruisers::selectZeroOrMore()
    def self.selectZeroOrMore()
        items = DataCenter::mikuType("NxCruiser")
                    .sort_by{|item| TxCores::coreDayCompletionRatio(item["engine"]) }
        selected, _ = LucilleCore::selectZeroOrMore("item", [], items, lambda{|item| NxCruisers::toString(item) })
        selected
    end

    # NxCruisers::interactivelySelectShipAndAddTo(item)
    def self.interactivelySelectShipAndAddTo(item)
        ship = NxCruisers::interactivelySelectOneOrNull()
        return if ship.nil?
        DataCenter::setAttribute(item["uuid"], "stackuuid", ship["uuid"])
    end

    # NxCruisers::selectSubsetAndMoveToSelectedShip(items)
    def self.selectSubsetAndMoveToSelectedShip(items)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        ship = NxCruisers::interactivelySelectOneOrNull()
        return if ship.nil?
        selected.each{|item|
            DataCenter::setAttribute(item["uuid"], "stackuuid", ship["uuid"])
        }
    end

    # NxCruisers::topPosition(item)
    def self.topPosition(item)
        ([0] + NxCruisers::stack(item).map{|task| task["global-positioning"] || 0 }).min
    end

    # ------------------
    # Ops

    # NxCruisers::access(item)
    def self.access(item)
        if item["field11"] then
            answer = LucilleCore::askQuestionAnswerAsBoolean("Would you like to acess the field11 ? ", true)
            if answer then
                CoreDataRefStrings::accessAndMaybeEdit(item["uuid"], item["field11"])
            end
        end
        NxCruisers::program1(item)
    end

    # NxCruisers::natural(item)
    def self.natural(item)
        NxBalls::start(item)
        if item["field11"] then
            CoreDataRefStrings::accessAndMaybeEdit(item["uuid"], item["field11"])
        end
        if NxCruisers::stack(item).size > 0 then
            NxCruisers::program1(item)
        end
        NxBalls::stop(item)
    end

    # NxCruisers::pile(item)
    def self.pile(item)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                DataCenter::setAttribute(task["uuid"], "stackuuid", item["uuid"])
                DataCenter::setAttribute(task["uuid"], "global-positioning", NxCruisers::topPosition(item) - 1)
            }
    end

    # NxCruisers::program1(item)
    def self.program1(item)
        loop {

            item = DataCenter::itemOrNull(item["uuid"])
            return if item.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(item, false)
            puts  Listing::toString2(store, item)
            puts  ""

            Prefix::prefix(NxCruisers::stack(item))
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            puts "task | top | pile | sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                DataCenter::setAttribute(task["uuid"], "stackuuid", item["uuid"])
                next
            end

            if input == "top" then
                line = LucilleCore::askQuestionAnswerAsString("description: ")
                next if line == ""
                task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                DataCenter::setAttribute(task["uuid"], "stackuuid", item["uuid"])
                DataCenter::setAttribute(task["uuid"], "global-positioning", NxCruisers::topPosition(item) - 1)
                next
            end

            if input == "pile" then
                NxCruisers::pile(item)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("item", [], NxCruisers::stack(item), lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    DataCenter::setAttribute(item["uuid"], "global-positioning", NxCruisers::topPosition(item) - 1)
                }
                next
            end

            if input == "move" then
                NxCruisers::selectSubsetAndMoveToSelectedShip(NxCruisers::stack(item))
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxCruisers::program2()
    def self.program2()
        loop {

            items = DataCenter::mikuType("NxCruiser")
            return if items.empty?

            system("clear")

            store = ItemStore.new()

            puts  ""

            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input.start_with?("..") then
                indx = input[2, 9].strip.to_i
                item = store.get(indx)
                next if item.nil?
                NxCruisers::program1(item)
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxCruisers::done(item)
    def self.done(item)
        DoNotShowUntil::setUnixtime(item["uuid"], CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()))
    end
end
