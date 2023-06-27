
class NxShips

    # ----------------------------------------------
    # Building

    # NxShips::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        engine = TxEngines::interactivelyMakeEngineOrNull()
        return if engine.nil?

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        DarkEnergy::init("NxShip", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "engine", engine)
        DarkEnergy::itemOrNull(uuid)
    end

    # ----------------------------------------------
    # Data

    # NxShips::toString(ship)
    def self.toString(ship)
        "⛵️ #{ship["description"]}"
    end

    # NxShips::toStringWithDetails(ship)
    def self.toStringWithDetails(ship)
        padding = XCache::getOrDefaultValue("e8f9022e-3a5d-4e3b-87e0-809a3308b8ad", "0").to_i
        engineSuffix = ship["engine"] ? " #{TxEngines::toString(ship["engine"])}" : ""
        "⛵️ #{ship["description"].ljust(padding)}#{engineSuffix}"
    end

    # NxShips::toStringForListing(ship)
    def self.toStringForListing(ship)
        padding = XCache::getOrDefaultValue("e8f9022e-3a5d-4e3b-87e0-809a3308b8ad", "0").to_i
        engineSuffix = ship["engine"] ? " ⏱️  #{"%6.2f" % (TxEngines::dayCompletionRatio(ship["engine"])*100)} %" : ""
        "⛵️ #{ship["description"].ljust(padding)}#{engineSuffix}"
    end

    # ----------------------------------------------
    # Ops

    # NxShips::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        ships = DarkEnergy::mikuType("NxShip").sort_by{|item| item["description"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("ship", ships, lambda{|ship| NxShips::toString(ship) })
    end

    # NxShips::architectThreadOrNull()
    def self.architectThreadOrNull()
        ship = NxShips::interactivelySelectOneOrNull()
        return ship if ship
        puts "No ship selected. Making a new one."
        NxShips::interactivelyIssueNewOrNull()
    end

    # NxShips::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("NxShip").each{|ship|
            next if ship["engine"].nil?
            engine = TxEngines::engine_maintenance(ship, ship["engine"])
            next if engine.nil?
            DarkEnergy::patch(ship["uuid"], "engine", engine)
        }
    end

    # NxShips::maintenance2()
    def self.maintenance2()
        padding = ([0] + DarkEnergy::mikuType("NxShip").map{|ship| ship["description"].size}).max
        XCache::set("e8f9022e-3a5d-4e3b-87e0-809a3308b8ad", padding)
    end

    # NxShips::program1(ship)
    def self.program1(ship)
        loop {

            ship = DarkEnergy::itemOrNull(ship["uuid"])
            return if ship.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            store.register(ship, false)
            spacecontrol.putsline Listing::itemToListingLine(store, ship)

            if ship["engine"] then
                spacecontrol.putsline ""
                spacecontrol.putsline "engine:"
                spacecontrol.putsline "- #{TxEngines::toString(ship["engine"])}"
            end

            spacecontrol.putsline ""
            items = Tx8s::childrenInOrder(ship)

            if items.size > 0 then
                items = Pure::pureFromItem(items.first) + items.drop(1)
            end

            Listing::printing(spacecontrol, store, items)

            spacecontrol.putsline ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                NxTasks::interactivelyIssueNewAtParentOrNull(ship)
                next
            end

            if input == "engine" then
                if ship["engine"] then
                    puts "You cannot reset an engine, modify the hour during maintenance"
                    LucilleCore::pressEnterToContinue()
                    next
                else
                    engine = TxEngines::interactivelyMakeEngineOrNull()
                    DarkEnergy::patch(ship["uuid"], "engine", engine)
                end
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxShips::program2()
    def self.program2()
        loop {
            ships = DarkEnergy::mikuType("NxShip").sort_by{|item| item["description"] }
            ship = LucilleCore::selectEntityFromListOfEntitiesOrNull("ship", ships, lambda{|ship| NxShips::toStringWithDetails(ship) })
            return if ship.nil?
            NxShips::program1(ship)
        }
    end

    # NxShips::interactivelyPutSomewhereAttempt(item)
    def self.interactivelyPutSomewhereAttempt(item)
        ship = NxShips::architectThreadOrNull()
        return if ship.nil?
        Tx8s::interactivelyPutIntoParentAttempt(item, ship)
    end
end

