
class TxStacks

    # TxStacks::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "TxStack",
            "description" => description
        }
    end

    # TxStacks::toString(item, positionDisplayStyle = "stack")
    def self.toString(item, positionDisplayStyle = "stack")
         "👨🏻‍💻 (stack)#{Parenting::positionSuffix(item, positionDisplayStyle)} #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # TxStacks::interactivelySelectPosition(stack)
    def self.interactivelySelectPosition(stack)
        puts TxStacks::toString(stack).green
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
            puts Listing::itemToListingLine(store, stack, "stack")

            puts ""
            Parenting::children_ordered(stack)
                .each{|item|
                    store.register(item, false)
                    puts Listing::itemToListingLine(store, item, "stack")
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
                position = Parenting::interactivelyDecideRelevantPositionAtParent(stack)
                DarkEnergy::commit(child) # commiting the child after deciding a position
                Parenting::set_objects(stack, child, position) # setting relationship after (!) the two objects are written
                next
            end
            if input == "pool" then
                child = TxPools::interactivelyMakeOrNull()
                next if child.nil?
                puts JSON.pretty_generate(child)
                position = Parenting::interactivelyDecideRelevantPositionAtParent(stack)
                DarkEnergy::commit(child) # commiting the child after deciding a position
                Parenting::set_objects(stack, child, position) # setting relationship after (!) the two objects are written
                next
            end
            if input == "stack" then
                child = TxStacks::interactivelyMakeOrNull()
                next if child.nil?
                puts JSON.pretty_generate(child)
                position = Parenting::interactivelyDecideRelevantPositionAtParent(stack)
                DarkEnergy::commit(child) # commiting the child after deciding a position
                Parenting::set_objects(stack, child, position) # setting relationship after (!) the two objects are written
                next
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end