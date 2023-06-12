
class TxPools

    # TxPools::issue(description)
    def self.issue(description)
        uuid = SecureRandom.uuid
        DarkEnergy::init("TxPool", uuid)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # TxPools::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        TxPools::issue(description)
    end

    # TxPools::toString(item)
    def self.toString(item)
        "👩‍💻 #{item["description"]}"
    end

    # TxPools::program(pool)
    def self.program(pool)
        loop {

            system("clear")

            store = ItemStore.new()

            puts ""
            store.register(pool, false)
            puts Listing::itemToListingLine(store, pool)

            TxEdges::children_ordered(pool)
                .each{|item|
                    store.register(item, false)
                    Listing::itemToListingLine(store, item)
                }

            puts ""
            puts ".. (<n>) | task | child"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                task = NxTasks::interactivelyIssueNewOrNull()
                next if task.nil?
                TxEdges::issueEdge(pool, task, nil)
                next
            end

            if input == "child" then
                task = TxEdges::interativelyIssueNewChildOrNull()
                next if task.nil?
                TxEdges::issueEdge(pool, task, nil)
                next
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end