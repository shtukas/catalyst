
class NxCruisers

    # NxCruisers::issueWithInit(uuid, description, engine)
    def self.issueWithInit(uuid, description, engine)
        Cubes::itemInit(uuid, "NxCruiser")
        Cubes::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute(uuid, "engine-0020", engine)
        Cubes::setAttribute(uuid, "description", description)
        Cubes::itemOrNull(uuid)
    end

    # NxCruisers::interactivelyIssueNewOrNull2(uuid)
    def self.interactivelyIssueNewOrNull2(uuid)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        core = TxCores::interactivelyMakeNewOrNull()
        return if core.nil?
        NxCruisers::issueWithInit(uuid, description, core)
    end

    # NxCruisers::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        NxCruisers::interactivelyIssueNewOrNull2(uuid)
    end

    # ------------------
    # Data

    # NxCruisers::toString(item, context = nil)
    def self.toString(item, context = nil)
        icon = NxCruisers::isTopShip(item) ? "⛵️" : "🔺"
        if item["uuid"] == "60949c4f-4e1f-45d3-acb4-3b6c718ac1ed" then # orphaned tasks (automatic)
            count = LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataHub/Buffer-In").select{|location| !File.basename(location).start_with?(".") }
            if count then
                return "#{icon}#{TxCores::suffix1(item["engine-0020"], context)} special circumstances: DataHub/Buffer-In"
            end
        end
        
        "#{icon}#{TxCores::suffix1(item["engine-0020"], context)} #{item["description"]}"
    end

    # NxCruisers::metric(item, indx)
    def self.metric(item, indx)
        core = item["engine-0020"]
        if core["type"] == "blocking-until-done" then
            return 0.75 + 0.01 * 1.to_f/(indx+1)
        end
        if core["type"] == "booster" then
            ratio = TxCores::coreDayCompletionRatio(core)
            if ratio >= 1 then
                return 0.1
            end
            return 0.60 + 0.10 * (1-ratio)
        end
        0.30 + 0.20 * 1.to_f/(indx+1)
    end

    # NxCruisers::recursiveDescent(ships)
    def self.recursiveDescent(ships)
        ships
            .map{|ship| NxCruisers::elements(ship).select{|i| i["mikuType"] == "NxCruiser" }.sort_by{|item| TxCores::coreDayCompletionRatio(item["engine-0020"]) } + [ship]}
            .flatten
    end

    # NxCruisers::isTopShip(item)
    def self.isTopShip(item)
        item["parentuuid-0032"].nil? or Cubes::itemOrNull(item["parentuuid-0032"]).nil? 
    end

    # NxCruisers::topShips()
    def self.topShips()
        Cubes::mikuType("NxCruiser")
            .select{|item| NxCruisers::isTopShip(item) }
    end

    # NxCruisers::shipsInRecursiveDescent()
    def self.shipsInRecursiveDescent()
        topShips = NxCruisers::topShips()
                    .sort_by{|item| TxCores::coreDayCompletionRatio(item["engine-0020"]) }
        NxCruisers::recursiveDescent(topShips)
    end

    # NxCruisers::listingItems()
    def self.listingItems()
        items1 = Cubes::mikuType("NxCruiser")
                    .select{|ship| ship["engine-0020"]["type"] == "booster" }
                    .select{|ship| TxCores::coreDayCompletionRatio(ship["engine-0020"]) < 1 }
                    .sort_by{|ship| TxCores::coreDayCompletionRatio(ship["engine-0020"]) }

        items2 = NxCruisers::shipsInRecursiveDescent()
                    .select{|ship| TxCores::coreDayCompletionRatio(ship["engine-0020"]) < 1 }
                    .sort_by{|ship| TxCores::coreDayCompletionRatio(ship["engine-0020"]) }

        items1 + items2
    end

    # NxCruisers::elements(cruiser)
    def self.elements(cruiser)
        if cruiser["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            return Cubes::mikuType("NxTask")
                    .select{|item| NxTasks::isOrphan(item) }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        if cruiser["uuid"] == "1c699298-c26c-47d9-806b-e19f84fd5d75" then # waves !interruption (automatic)
            return Waves::listingItems().select{|item| !item["interruption"] }
        end
        if cruiser["uuid"] == "eadf9717-58a1-449b-8b99-97c85a154fbc" then # backups (automatic)
            return Config::isPrimaryInstance() ? Backups::listingItems() : []
        end
        if cruiser["description"].include?("patrol") then
            elements = Cubes::items()
                        .select{|item| item["parentuuid-0032"] == cruiser["uuid"] }
            return elements.sort_by{|i| i["unixtime"] }
        end

        Cubes::items()
            .select{|item| item["parentuuid-0032"] == cruiser["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxCruisers::elementsForPrefix(cruiser)
    def self.elementsForPrefix(cruiser)
        if cruiser["uuid"] == "06ebad3e-2ecf-4acd-9eea-00cdaa6acdc3" then # orphaned tasks (automatic)
            return Cubes::mikuType("NxTask")
                    .select{|item| NxTasks::isOrphan(item) }
                    .sort_by{|item| item["global-positioning"] || 0 }
        end
        if cruiser["uuid"] == "1c699298-c26c-47d9-806b-e19f84fd5d75" then # waves !interruption (automatic)
            return Waves::listingItems().select{|item| !item["interruption"] }
        end
        if cruiser["uuid"] == "eadf9717-58a1-449b-8b99-97c85a154fbc" then # backups (automatic)
            return Config::isPrimaryInstance() ? Backups::listingItems() : []
        end

        items = Cubes::items()
                .select{|item| item["parentuuid-0032"] == cruiser["uuid"] }

        i1, i2 = items.partition{|item| item["mikuType"] == "NxCruiser" }
        i1.sort_by{|item| TxCores::coreDayCompletionRatio(item["engine-0020"]) } + i2.sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxCruisers::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        #items = Cubes::mikuType("NxCruiser")
        #            .sort_by{|item| TxCores::coreDayCompletionRatio(item["engine-0020"]) }
        #LucilleCore::selectEntityFromListOfEntitiesOrNull("ship", items, lambda{|item| NxCruisers::toString(item) })
        NxCruisers::interactivelySelectShipUsingTopDownNavigationOrNull()
    end

    # NxCruisers::interactivelySelectOneTopShipOrNull()
    def self.interactivelySelectOneTopShipOrNull()
        topShips = NxCruisers::topShips()
                    .sort_by{|item| TxCores::coreDayCompletionRatio(item["engine-0020"]) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("ship", topShips, lambda{|item| NxCruisers::toString(item) })
    end

    # NxCruisers::interactivelySelectShipUsingTopDownNavigationOrNull(ship = nil)
    def self.interactivelySelectShipUsingTopDownNavigationOrNull(ship = nil)
        if ship.nil? then
            ship = NxCruisers::interactivelySelectOneTopShipOrNull()
            return nil if ship.nil?
            return NxCruisers::interactivelySelectShipUsingTopDownNavigationOrNull(ship)
        end
        childrenships = NxCruisers::elements(ship).select{|item| item["mikuType"] == "NxCruiser" }.sort_by{|item| TxCores::coreDayCompletionRatio(item["engine-0020"]) }
        if childrenships.empty? then
            return ship
        end
        selected = LucilleCore::selectEntityFromListOfEntitiesOrNull("ship", [ship] + childrenships, lambda{|item| NxCruisers::toString(item) })
        if selected["uuid"] == ship["uuid"] then
            return selected
        end
        NxCruisers::interactivelySelectShipUsingTopDownNavigationOrNull(selected)
    end

    # NxCruisers::selectZeroOrMore()
    def self.selectZeroOrMore()
        items = Cubes::mikuType("NxCruiser")
                    .sort_by{|item| TxCores::coreDayCompletionRatio(item["engine-0020"]) }
        selected, _ = LucilleCore::selectZeroOrMore("item", [], items, lambda{|item| NxCruisers::toString(item) })
        selected
    end

    # NxCruisers::interactivelySelectShipAndAddTo(itemuuid)
    def self.interactivelySelectShipAndAddTo(itemuuid)
        ship = NxCruisers::interactivelySelectOneOrNull()
        return if ship.nil?
        Cubes::setAttribute(itemuuid, "parentuuid-0032", ship["uuid"])
    end

    # NxCruisers::selectSubsetAndMoveToSelectedShip(items)
    def self.selectSubsetAndMoveToSelectedShip(items)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        ship = NxCruisers::interactivelySelectOneOrNull()
        return if ship.nil?
        selected.each{|item|
            Cubes::setAttribute(item["uuid"], "parentuuid-0032", ship["uuid"])
        }
    end

    # NxCruisers::topPosition(item)
    def self.topPosition(item)
        ([0] + NxCruisers::elements(item).map{|task| task["global-positioning"] || 0 }).min
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
                Cubes::setAttribute(task["uuid"], "parentuuid-0032", item["uuid"])
                Cubes::setAttribute(task["uuid"], "global-positioning", NxCruisers::topPosition(item) - 1)
            }
    end

    # NxCruisers::program1(item)
    def self.program1(item)
        loop {

            item = Cubes::itemOrNull(item["uuid"])
            return if item.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(item, false)
            puts  Listing::toString2(store, item)
            puts  ""

            Prefix::prefix(NxCruisers::elements(item))
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString3(store, item)
                }

            puts ""

            puts "top | pile | task | patrol | ship | sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Cubes::setAttribute(task["uuid"], "parentuuid-0032", item["uuid"])
                next
            end

            if input == "patrol" then
                patrol = NxPatrols::interactivelyIssueNewOrNull()
                next if patrol.nil?
                puts JSON.pretty_generate(patrol)
                Cubes::setAttribute(patrol["uuid"], "parentuuid-0032", item["uuid"])
                next
            end

            if input == "ship" then
                ship = NxCruisers::interactivelyIssueNewOrNull()
                next if ship.nil?
                puts JSON.pretty_generate(ship)
                Cubes::setAttribute(ship["uuid"], "parentuuid-0032", item["uuid"])
                next
            end

            if input == "top" then
                line = LucilleCore::askQuestionAnswerAsString("description: ")
                next if line == ""
                task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                puts JSON.pretty_generate(task)
                Cubes::setAttribute(task["uuid"], "parentuuid-0032", item["uuid"])
                Cubes::setAttribute(task["uuid"], "global-positioning", NxCruisers::topPosition(item) - 1)
                next
            end

            if input == "pile" then
                NxCruisers::pile(item)
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("item", [], NxCruisers::elements(item), lambda{|i| PolyFunctions::toString(i) })
                selected.reverse.each{|i|
                    Cubes::setAttribute(i["uuid"], "global-positioning", NxCruisers::topPosition(item) - 1)
                }
                next
            end

            if input == "move" then
                NxCruisers::selectSubsetAndMoveToSelectedShip(NxCruisers::elements(item))
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxCruisers::program2()
    def self.program2()
        loop {

            items = NxCruisers::shipsInRecursiveDescent()
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
