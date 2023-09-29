
class NxCollections

    # NxCollections::issue(description)
    def self.issue(description)
        uuid = SecureRandom.uuid
        Events::publishItemInit("NxCollection", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Catalyst::itemOrNull(uuid)
    end

    # NxCollections::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxCollections::issue(description)
    end

    # NxCollections::toString(item)
    def self.toString(item)
        "✨ #{item["description"]}"
    end

    # NxCollections::listingItems()
    def self.listingItems()
        Catalyst::mikuType("NxCollection").sort_by{|item| item["unixtime"] }
    end

    # NxCollections::interactivelySelectNewOrNull()
    def self.interactivelySelectNewOrNull()
        items = Catalyst::mikuType("NxCollection").sort_by{|item| item["unixtime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("collection", items, lambda{ |item| PolyFunctions::toString(item) })
    end

    # NxCollections::architectCollection()
    def self.architectCollection()
        collection = NxCollections::interactivelySelectNewOrNull()
        return collection if collection
        puts "You have not selected a collection"
        options = ["select again", "make a new one"]
        option = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("option", options)
        if option == "select again" then
            return NxCollections::architectCollection()
        end
        if option == "make a new one" then
            loop {
                collection = NxCollections::interactivelyIssueNewOrNull()
                next if collection.nil?
                return collection
            }
        end
    end

    # NxCollections::childrenInOrder(collection)
    def self.childrenInOrder(collection)
        Catalyst::mikuType("NxTask")
            .select{|item| item["collection-21ef"] == collection["uuid"] }
            .sort_by{|item| item["global-position"] }
    end

    # NxCollections::program1(collection)
    def self.program1(collection)
        loop {

            collection = Catalyst::itemOrNull(collection["uuid"])
            return if collection.nil?

            system("clear")

            store = ItemStore.new()

            puts  ""
            store.register(collection, false)
            puts  Listing::toString2(store, collection)
            puts  ""

            NxCollections::childrenInOrder(collection)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts  Listing::toString2(store, item)
                }

            puts ""
            puts "task | pile | pile * | sort "
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull_withoutCollectionChoice()
                next if task.nil?
                puts JSON.pretty_generate(task)
                Events::publishItemAttributeUpdate(uuid, "collection-21ef", collection["uuid"])
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
                        task = NxTasks::descriptionToTask1(SecureRandom.uuid, line)
                        puts JSON.pretty_generate(task)
                        Events::publishItemAttributeUpdate(task["uuid"], "global-position", NxTasks::newGlobalFirstPosition)
                        Events::publishItemAttributeUpdate(task["uuid"], "collection-21ef", collection["uuid"])
                    }
                    next
                next
            end

            if Interpreting::match("sort", input) then
                items = NxCollections::childrenInOrder(collection)
                selected, _ = LucilleCore::selectZeroOrMore("items", [], items, lambda{|item| PolyFunctions::toString(item) })
                selected.reverse.each{|item|
                    Events::publishItemAttributeUpdate(item["uuid"], "global-position", NxTasks::newGlobalFirstPosition())
                }
                next
            end

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # NxCollections::program2()
    def self.program2()
        loop {
            collection = NxCollections::interactivelySelectNewOrNull()
            return if collection.nil?
            NxCollections::program1(collection)
        }
    end
end