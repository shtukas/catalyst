
class NxBoxes

    # ----------------------------------------------
    # Building

    # NxBoxes::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        DarkEnergy::init("NxBox", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # ----------------------------------------------
    # Data

    # NxBoxes::toString(box)
    def self.toString(box)
        "🗄️  #{box["description"]}"
    end

    # NxBoxes::boxSuffix(item)
    def self.boxSuffix(item)
        parent = Tx8s::getParentOrNull(item)
        return "" if parent.nil?
        return "" if parent["mikuType"] != "NxBox"
        " (#{parent["description"].green})"
    end

    # ----------------------------------------------
    # Ops

    # NxBoxes::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        ships = DarkEnergy::mikuType("NxBox").sort_by{|item| item["description"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("box", ships, lambda{|box| NxBoxes::toString(box) })
    end

    # NxBoxes::architectThreadOrNull()
    def self.architectThreadOrNull()
        box = NxBoxes::interactivelySelectOneOrNull()
        return box if box
        puts "No box selected. Making a new one."
        NxBoxes::interactivelyIssueNewOrNull()
    end

    # NxBoxes::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("NxBox").each{|box|
            next if box["engine"].nil?
            engine = TxCores::core_maintenance(box, box["engine"])
            next if engine.nil?
            DarkEnergy::patch(box["uuid"], "engine", engine)
        }
    end

    # NxBoxes::program1(box)
    def self.program1(box)
        loop {

            box = DarkEnergy::itemOrNull(box["uuid"])
            return if box.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            store.register(box, false)
            spacecontrol.putsline Listing::itemToListingLine(store, box)

            spacecontrol.putsline ""
            items = Tx8s::childrenInOrder(box)

            Listing::printing(spacecontrol, store, items)

            spacecontrol.putsline ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                NxTasks::interactivelyIssueNewAtParentOrNull(box)
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxBoxes::program2()
    def self.program2()
        loop {
            ships = DarkEnergy::mikuType("NxBox").sort_by{|item| item["description"] }
            box = LucilleCore::selectEntityFromListOfEntitiesOrNull("box", ships, lambda{|box| NxBoxes::toString(box) })
            return if box.nil?
            NxBoxes::program1(box)
        }
    end

    # NxBoxes::interactivelySelectParentAndAttachAttempt(item)
    def self.interactivelySelectParentAndAttachAttempt(item)
        box = NxBoxes::architectThreadOrNull()
        return if box.nil?
        Tx8s::interactivelyPutIntoParentAttempt(item, box)
    end
end

