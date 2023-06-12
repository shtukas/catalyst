
class TxStacks

    # TxStacks::issue(description)
    def self.issue(description)
        uuid = SecureRandom.uuid
        DarkEnergy::init("TxStack", uuid)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # TxStacks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        TxStacks::issue(description)
    end

    # TxStacks::toString(item)
    def self.toString(item)
        "👨🏻‍💻 #{item["description"]}"
    end

    # TxStacks::interactivelySelectPosition(stack)
    def self.interactivelySelectPosition(stack)
        puts TxStacks::toString(item).green
        TxEdges::children_ordered(stack).each{|item|
            position = TxEdges::getPositionOrNull(stack, item)
            puts "    - (#{"%6.3f" % position}) #{PolyFunctions::toString(item)}"
        }
        position = 0
        loop {
            position = LucilleCore::askQuestionAnswerAsString("position: ")
            break if position != ""
        }
        position.to_f
    end

    # TxPools::program(stack)
    def self.program(stack)
        loop {

            system("clear")

            store = ItemStore.new()

            puts ""
            store.register(stack, false)
            puts Listing::itemToListingLine(store, stack)

            TxEdges::children_ordered(stack)
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
                TxEdges::issueEdge(stack, task, nil)
                next
            end

            if input == "child" then
                task = TxEdges::interativelyIssueNewChildOrNull()
                next if task.nil?
                TxEdges::issueEdge(stack, task, nil)
                next
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end