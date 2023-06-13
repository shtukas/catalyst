
class TxStacks

    # TxStacks::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        {
            "uuid"        => uuid,
            "mikuType"    => "TxStack",
            "description" => description
        }
    end

    # TxStacks::toString(item)
    def self.toString(item)
        "👨🏻‍💻 #{item["description"]}"
    end

    # TxStacks::interactivelySelectPosition(stack)
    def self.interactivelySelectPosition(stack)
        puts TxStacks::toString(item).green
        Parenting::children_ordered(stack).each{|item|
            position = Parenting::getPositionOrNull(stack, item)
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

            Parenting::children_ordered(stack)
                .each{|item|
                    store.register(item, false)
                    Listing::itemToListingLine(store, item)
                }

            puts ""
            puts ".. (<n>) | child"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "child" then
                Parenting::interactivelyIssueChildOrNothing(stack)
                next
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end