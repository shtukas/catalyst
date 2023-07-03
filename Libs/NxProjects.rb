
class NxProjects

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxProject", uuid)
        engine = TxEngines::interactivelyMakeEngine()
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "engine", engine)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxProjects::interactivelyIssueNewAtParentOrNull(parent)
    def self.interactivelyIssueNewAtParentOrNull(parent)
        position = Tx8s::interactivelyDecidePositionUnderThisParent(parent)
        tx8 = Tx8s::make(parent["uuid"], position)

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid
        DarkEnergy::init("NxProject", uuid)
        engine = TxEngines::interactivelyMakeEngine()
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "engine", engine)
        DarkEnergy::patch(uuid, "parent", tx8)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxProjects::toString(item)
    def self.toString(item)
        "⛵️ #{item["description"]}#{CoreData::itemToSuffixString(item)} #{TxEngines::toString(item["engine"])}"
    end

    # NxProjects::toStringForMainListing(item)
    def self.toStringForMainListing(item)
        "⛵️ #{item["description"]}#{CoreData::itemToSuffixString(item)}#{NxCores::coreSuffix(item)} #{TxEngines::toString(item["engine"])}"
    end

    # NxProjects::toStringForCoreListing(item)
    def self.toStringForCoreListing(item)
        "⛵️#{Tx8s::positionInParentSuffix(item)} #{item["description"]}#{CoreData::itemToSuffixString(item)}#{NxCores::coreSuffix(item)} #{TxEngines::toString(item["engine"])}"
    end

    # NxProjects::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxProject").select{|project|
            TxEngines::compositeCompletionRatio(project["engine"]) < 1
        }
    end

    # NxProjects::maintenance()
    def self.maintenance()
        # Ensuring consistency of parenting targets
        DarkEnergy::mikuType("NxProject").each{|project|
            next if project["parent"].nil?
            if DarkEnergy::itemOrNull(project["parent"]["uuid"]).nil? then
                DarkEnergy::patch(uuid, "parent", nil)
            end
        }

        # More orphan tasks to Infinity
        DarkEnergy::mikuType("NxProject").each{|project|
            next if project["parent"]
            parent = DarkEnergy::itemOrNull(NxCores::infinityuuid())
            project["parent"] = Tx8s::make(parent["uuid"], Tx8s::newFirstPositionAtThisParent(parent))
            DarkEnergy::commit(project)
        }

        DarkEnergy::mikuType("TxProject").each{|project|
            engine = project["engine"]
            engine = TxEngines::engine_maintenance(engine)
            next if engine.nil?
            DarkEnergy::patch(project["uuid"], "engine", engine)
        }
    end

    # NxProjects::program1(project)
    def self.program1(project)
        loop {

            project = DarkEnergy::itemOrNull(project["uuid"])
            return if project.nil?

            system("clear")

            store = ItemStore.new()
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            spacecontrol.putsline ""
            store.register(project, false)
            spacecontrol.putsline NxCores::itemToStringListing(store, project)

            spacecontrol.putsline ""
            items = Tx8s::childrenInOrder(project)

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
                NxTasks::interactivelyIssueNewAtParentOrNull(project)
                next
            end

            if input == "pile" then
                Tx8s::pileAtThisParent(project)
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end
end
