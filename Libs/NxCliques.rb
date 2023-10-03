

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
        count = NxCliques::elementsInOrder(item).size
        "▫️  #{TxEngine::prefix(item)}#{item["description"]}#{TxCores::suffix(item)} (#{count.to_s.rjust(3)})"
    end

    # NxCliques::cliquesInPriorityOrder()
    def self.cliquesInPriorityOrder()
        Catalyst::mikuType("NxClique").sort_by{|item| TxEngine::ratio(item["engine-2251"]) }
    end

    # NxCliques::elementsInOrder(clique)
    def self.elementsInOrder(clique)
        Catalyst::catalystItems()
            .select{|item| item["clique-0037"] == clique["uuid"] }
            .sort_by {|item| item["global-position"] }
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
        Events::publishItemAttributeUpdate(task["uuid"], "clique-0037", clique["uuid"])
        Events::publishItemAttributeUpdate(task["uuid"], "global-position", Catalyst::newGlobalLastPosition())
    end

    # NxCliques::prepend(clique, task)
    def self.prepend(clique, task)
        Events::publishItemAttributeUpdate(task["uuid"], "clique-0037", clique["uuid"])
        Events::publishItemAttributeUpdate(task["uuid"], "global-position", Catalyst::newGlobalFirstPosition())
    end

    # NxCliques::pile3(clique)
    def self.pile3(clique)
        text = CommonUtils::editTextSynchronously("").strip
        return if text == ""
        text
            .lines
            .map{|line| line.strip }
            .reverse
            .each{|line|
                task = NxTasks::descriptionToTask1(SecureRandom.uuid, line)
                puts JSON.pretty_generate(task)
                NxCliques::prepend(clique, task)
            }
    end

    # NxCliques::program1(clique)
    def self.program1(clique)
        loop {

            clique = Catalyst::itemOrNull(clique["uuid"])
            return if clique.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(clique, false)
            puts  Listing::toString2(store, clique)
            puts  ""

            NxCliques::elementsInOrder(clique)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            puts "task | pile | sort"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Events::publishItemAttributeUpdate(task["uuid"], "clique-0037", clique["uuid"])
                next
            end

            if input == "pile" then
                NxCliques::pile3(clique)
                next
            end

            if input == "sort" then
                items = NxCliques::elementsInOrder(clique)
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

    # NxCliques::program2()
    def self.program2()
        loop {
            clique = NxCliques::interactivelySelectOneOrNull()
            return if clique.nil?
            NxCliques::program1(clique)
        }
    end
end
