
class NxCollections

    # NxCollections::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxCollection", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxCollections::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        position = Tx8s::interactivelyDecidePositionUnderThisParent(parent)
        tx8 = Tx8s::make(parent["uuid"], position)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        DarkEnergy::init("NxCollection", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "parent", tx8)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxCollections::toString(item)
    def self.toString(item)
        "🫧 #{item["description"]}#{NxCores::coreSuffix(item)}"
    end

    # NxCollections::toStringForMainListing(item)
    def self.toStringForMainListing(item)
        "🫧 #{item["description"]}#{NxCores::coreSuffix(item)}"
    end

    # NxCollections::toStringForCoreListing(item)
    def self.toStringForCoreListing(item)
        "🫧#{Tx8s::positionInParentSuffix(item)} #{item["description"]}"
    end

    # NxCollections::maintenance()
    def self.maintenance()
        # Ensuring consistency of parenting targets
        DarkEnergy::mikuType("NxCollection").each{|project|
            next if project["parent"].nil?
            if DarkEnergy::itemOrNull(project["parent"]["uuid"]).nil? then
                DarkEnergy::patch(uuid, "parent", nil)
            end
        }

        # Move orphan item to Infinity
        DarkEnergy::mikuType("NxCollection").each{|project|
            next if project["parent"]
            parent = DarkEnergy::itemOrNull(NxCores::infinityuuid())
            project["parent"] = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))
            DarkEnergy::commit(project)
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
            puts "(task, pile)"
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

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end
