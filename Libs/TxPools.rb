
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
        "👩‍💻 (pool)#{Parenting::positionSuffix(item)} #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # TxPools::program(pool)
    def self.program(pool)
        loop {

            system("clear")

            store = ItemStore.new()

            puts ""
            store.register(pool, false)
            puts Listing::itemToListingLine(store, pool)

            puts ""
            Parenting::children(pool)
                .sort_by{|item| Bank::recoveredAverageHoursPerDay(item["uuid"]) }
                .each{|item|
                    store.register(item, false)
                    puts Listing::itemToListingLine(store, item)
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