
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

    # TxPools::toString(item, positionDisplayStyle)
    def self.toString(item, positionDisplayStyle = "stack")
        "👩‍💻 (pool)#{Parenting::positionSuffix(item, positionDisplayStyle)} #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # TxPools::program(pool)
    def self.program(pool)
        loop {

            system("clear")

            store = ItemStore.new()

            puts ""
            store.register(pool, false)
            puts Listing::itemToListingLine(store, pool, "stack")

            puts ""
            Parenting::children(pool)
                .each{|item|
                    store.register(item, false)
                    puts Listing::itemToListingLine(store, item, "pool")
                }

            puts ""
            puts ".. (<n>) | task | pool | stack"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                child = NxTasks::interactivelyMakeOrNull()
                next if child.nil?
                puts JSON.pretty_generate(child)
                position = Parenting::interactivelyDecideRelevantPositionAtParent(pool)
                DarkEnergy::commit(child) # commiting the child after (!) deciding a position
                Parenting::set_objects(pool, child, position) # setting relationship after (!) the two objects are written
                next
            end
            if input == "pool" then
                child = TxPools::interactivelyMakeOrNull()
                next if child.nil?
                puts JSON.pretty_generate(child)
                position = Parenting::interactivelyDecideRelevantPositionAtParent(pool)
                DarkEnergy::commit(child) # commiting the child after deciding a position
                Parenting::set_objects(pool, child, position) # setting relationship after (!) the two objects are written
                next
            end
            if input == "stack" then
                child = TxStacks::interactivelyMakeOrNull()
                next if child.nil?
                puts JSON.pretty_generate(child)
                position = Parenting::interactivelyDecideRelevantPositionAtParent(pool)
                DarkEnergy::commit(child) # commiting the child after deciding a position
                Parenting::set_objects(pool, child, position) # setting relationship after (!) the two objects are written
                next
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end