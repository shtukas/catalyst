
class NxShips

    # NxShips::issue(uuid, description)
    def self.issue(uuid, description)
        DataCenter::itemInit(uuid, "NxShip")
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::itemOrNull(uuid)
    end

    # NxShips::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        NxShips::issue(SecureRandom.uuid, description)
    end

    # ------------------
    # Data

    # NxShips::toString(item)
    def self.toString(item)
        "⛵️ #{TxEngines::string1(item)} #{item["description"]}"
    end

    # NxShips::cargo(ship)
    def self.cargo(ship)
        DataCenter::catalystItems()
            .select{|item| item["parent-0810"] == ship["uuid"] }
            .sort_by{|item| item["global-positioning"] || 0 }
    end

    # NxShips::topPosition(ship)
    def self.topPosition(ship)
        NxShips::cargo(ship)
            .reduce(0){|topPosition, item|
                [topPosition, item["global-positioning"] || 0].min
            }
    end

    # NxShips::listingItems()
    def self.listingItems()
        DataCenter::mikuType("NxShip")
            .select{|item| TxEngines::shouldShowInListing(item) }
            .sort_by{|item| item["engine-0916"] ? TxEngines::dayCompletionRatio(item["engine-0916"]) : 0 }
    end

    # NxShips::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        ships = DataCenter::mikuType("NxShip")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("ship", ships, lambda{|item| PolyFunctions::toString(item) })
    end

    # NxShips::interactivelySelectShipAndAddTo(item)
    def self.interactivelySelectShipAndAddTo(item)
        ship = NxShips::interactivelySelectOneOrNull()
        return if ship.nil?
        DataCenter::setAttribute(item["uuid"], "parent-0810", ship["uuid"])
    end

    # NxShips::selectSubsetAndMoveToSelectedShip(items)
    def self.selectSubsetAndMoveToSelectedShip(items)
        selected, _ = LucilleCore::selectZeroOrMore("selection", [], items, lambda{|item| PolyFunctions::toString(item) })
        return if selected.size == 0
        ship = NxShips::interactivelySelectOneOrNull()
        return if ship.nil?
        selected.each{|item|
            DataCenter::setAttribute(item["uuid"], "parent-0810", ship["uuid"])
        }
    end

    # ------------------
    # Ops

    # NxShips::openCyclesSync()
    def self.openCyclesSync()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/OpenCycles").each{|location|
            next if !File.directory?(location)
            next if File.basename(location).start_with?('.')
            markerfile = "#{location}/.marker-709b82a0903b"
            if !File.exist?(markerfile) then
                uuid = SecureRandom.uuid
                File.open(markerfile, "w"){|f| f.puts(uuid) }
                puts "Generating #{"NxShip".green} for '#{File.basename(location).green}'"
                LucilleCore::pressEnterToContinue()
                NxShips::issue(uuid, File.basename(location))
                next
            end
        }
    end

    # NxShips::program1(ship)
    def self.program1(ship)
        loop {

            ship = DataCenter::itemOrNull(ship["uuid"])
            return if ship.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(ship, false)
            puts  Listing::toString2(store, ship)
            puts  ""

            NxShips::cargo(ship)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            puts "task | pile | sort | move"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                DataCenter::setAttribute(task["uuid"], "parent-0810", ship["uuid"])
                next
            end

            if input == "pile" then
                text = CommonUtils::editTextSynchronously("").strip
                next if text == ""
                text
                    .lines
                    .map{|line| line.strip }
                    .reverse
                    .each{|line|
                        task = NxTasks::descriptionToTask1(SecureRandom.hex, line)
                        puts JSON.pretty_generate(task)
                        DataCenter::setAttribute(task["uuid"], "parent-0810", ship["uuid"])
                        DataCenter::setAttribute(task["uuid"], "global-positioning", NxShips::topPosition(ship) - 1)
                    }
                next
            end

            if input == "sort" then
                selected, _ = LucilleCore::selectZeroOrMore("item", [], NxShips::cargo(ship), lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    DataCenter::setAttribute(item["uuid"], "global-positioning", NxShips::topPosition(ship) - 1)
                }
                next
            end

            if input == "move" then
                NxShips::selectSubsetAndMoveToSelectedShip(NxShips::cargo(ship))
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end
