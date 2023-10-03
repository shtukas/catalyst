

class NxCliques

    # --------------------------------------------------
    # Makers

    # NxCliques::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        # We need to create the blade before we call CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull
        # because the blade need to exist for aion points data blobs to have a place to go.

        uuid = SecureRandom.uuid
        Events::publishItemInit("NxClique", uuid)

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

    # NxCliques::toString(item)
    def self.toString(item)
        count = Catalyst::elementsInOrder(item).size
        "▫️  #{TxEngine::prefix(item)}#{item["description"]}#{TxCores::suffix(item)} (#{count.to_s.rjust(3)})"
    end

    # NxCliques::cliquesInPriorityOrder()
    def self.cliquesInPriorityOrder()
        Catalyst::mikuType("NxClique").sort_by{|item| TxEngine::ratio(item["engine-2251"]) }
    end

    # NxCliques::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = Catalyst::mikuType("NxClique")
                    .sort_by{|item| TxEngine::ratio(item["engine-2251"]) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", items, lambda{|item| NxCliques::toString(item) })
    end

    # NxCliques::interactivelyArchitect()
    def self.interactivelyArchitect()
        clique = NxCliques::interactivelySelectOneOrNull()
        return clique if clique
        clique = NxCliques::interactivelyIssueNewOrNull()
        return clique if clique
        NxCliques::interactivelyArchitect()
    end

    # --------------------------------------------------
    # Operations

    # NxCliques::append(clique, task)
    def self.append(clique, task)
        Events::publishItemAttributeUpdate(task["uuid"], "parent-1328", clique["uuid"])
        Events::publishItemAttributeUpdate(task["uuid"], "global-position", Catalyst::newGlobalLastPosition())
    end

    # NxCliques::prepend(clique, task)
    def self.prepend(clique, task)
        Events::publishItemAttributeUpdate(task["uuid"], "parent-1328", clique["uuid"])
        Events::publishItemAttributeUpdate(task["uuid"], "global-position", Catalyst::newGlobalFirstPosition())
    end

    # NxCliques::program2()
    def self.program2()
        loop {
            clique = NxCliques::interactivelySelectOneOrNull()
            return if clique.nil?
            Catalyst::program1(clique)
        }
    end
end