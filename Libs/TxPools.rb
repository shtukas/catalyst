
class TxPools

    # TxPools::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        {
            "uuid"        => uuid,
            "mikuType"    => "TxPool",
            "description" => description
        }
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

            Parenting::children(pool)
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
                Parenting::interactivelyIssueChildOrNothing(pool)
                next
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end