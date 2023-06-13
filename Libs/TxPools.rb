
class TxPools

    # TxPools::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "TxPool",
            "description" => description
        }
    end

    # TxPools::toString(item)
    def self.toString(item)
        position = NxTasks::getItemPositionOrNull(item)
        if position then
            "👩‍💻 (#{"%5.2f" % position}) #{item["description"]}"
        else
            "👩‍💻 (missing position) #{item["description"]}"
        end
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
            puts ".. (<n>) | task | pool | stack"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                child = NxTasks::interactivelyMakeOrNull()
                next if child.nil?
                position = rand
                Parenting::set_objects(pool, child, position)
                next
            end
            if input == "pool" then
                child = TxPools::interactivelyMakeOrNull()
                next if child.nil?
                position = rand
                Parenting::set_objects(pool, child, position)
                next
            end
            if input == "stack" then
                child = TxStacks::interactivelyMakeOrNull()
                next if child.nil?
                position = rand
                Parenting::set_objects(pool, child, position)
                next
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end