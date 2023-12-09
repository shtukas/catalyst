
class NxCruisers

    # NxCruisers::issueWithInit(uuid, description, engine)
    def self.issueWithInit(uuid, description, engine)
        DataCenter::itemInit(uuid, "NxCruiser")
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "engine", engine)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::itemOrNull(uuid)
    end

    # NxCruisers::interactivelyIssueNewOrNull2(uuid)
    def self.interactivelyIssueNewOrNull2(uuid)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        engine = TxCores::interactivelyMakeNewOrNull()
        return if engine.nil?
        NxCruisers::issueWithInit(uuid, description, engine)
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
        if item["uuid"] == "60949c4f-4e1f-45d3-acb4-3b6c718ac1ed" then # orphaned tasks (automatic)
            count = LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataHub/Buffer-In").select{|location| !File.basename(location).start_with?(".") }
            if count then
                return "⛵️ #{TxCores::string1(item["engine"])} special circusmtances: DataHub/Buffer-In #{TxCores::string2(item["engine"]).yellow}"
            end
        end
        "⛵️ #{TxCores::string1(item["engine"])} #{item["description"]} #{TxCores::string2(item["engine"]).yellow}"
    end

    # NxCruisers::listingItems()
    def self.listingItems()
        DataCenter::mikuType("NxCruiser")
    end

    # NxCruisers::stack(cruiser)
    def self.stack(cruiser)
        if cruiser["uuid"] == "60949c4f-4e1f-45d3-acb4-3b6c718ac1ed" then # orphaned tasks (automatic)
            return DataCenter::mikuType("NxTask")
                    .select{|item| NxTasks::isOrphan(item) }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        if cruiser["uuid"] == "1c699298-c26c-47d9-806b-e19f84fd5d75" then # waves !interruption
            return Waves::listingItems().select{|item| !item["interruption"] }
        end
        if cruiser["uuid"] == "eadf9717-58a1-449b-8b99-97c85a154fbc" then # backups (automatic)
            return Config::isPrimaryInstance() ? Backups::listingItems() : []
        end
        DataCenter::mikuType("NxTask")
            .select{|item| item["stackuuid"] == cruiser["uuid"] }
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

    # NxCruisers::itemEta(item)
    def self.itemEta(item)
        dataL = lambda{|item|
            if TxBoosters::hasActiveBooster(item) then
                return [TxBoosters::completionRatio(item["booster-1521"]), item["booster-1521"]["hours"]]
            end
            [TxCores::coreDayCompletionRatio(item["engine"]), TxCores::coreDayHours(item["engine"])]
        }
        ratio, hours = dataL.call(item)
        [(1-ratio), 0].max * hours * 3600
    end

    # NxCruisers::eta()
    def self.eta()
        DataCenter::mikuType("NxCruiser")
            .select{|item| Listing::listable(item) }
            .map{|item| NxCruisers::itemEta(item) }
            .inject(0, :+)
    end

    # ------------------
    # Ops

    # NxCruisers::access(item)
    def self.access(item)
        NxCruisers::program1(item)
    end

    # NxCruisers::natural(item)
    def self.natural(item)
        NxCruisers::program1(item)
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
                    puts  Listing::toString3(store, item)
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
                        .sort_by{|item| Metrics::metric2(item) }
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
