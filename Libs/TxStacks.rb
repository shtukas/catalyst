
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

    # TxStacks::toString(item)
    def self.toString(item)
         "👨🏻‍💻 (stack)#{Parenting::positionSuffix(item)} #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # TxStacks::interactivelySelectPosition(stack)
    def self.interactivelySelectPosition(stack)
        puts TxStacks::toString(stack).green
        Parenting::childrenInPositionOrder(stack).each{|item|
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
            spacecontrol.putsline "@stack:"
            store.register(stack, false)
            puts Listing::itemToListingLine(store, stack)

            puts ""
            Parenting::childrenInPositionOrder(stack)
                .each{|item|
                    store.register(item, false)
                    puts Listing::itemToListingLine(store, item)
                }

            puts ""
            puts ".. (<n>) | task | pool | stack | destroy"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            if input == "task" then
                child = NxTasks::interactivelyMakeOrNull()
                next if child.nil?
                puts JSON.pretty_generate(child)
                position = Parenting::interactivelyDecideRelevantPositionAtCollection(stack)
                DarkEnergy::commit(child) # commiting the child after deciding a position
                Parenting::set_objects(stack, child, position) # setting relationship after (!) the two objects are written
                next
            end
            if input == "pool" then
                child = TxPools::interactivelyMakeOrNull()
                next if child.nil?
                puts JSON.pretty_generate(child)
                position = Parenting::interactivelyDecideRelevantPositionAtCollection(stack)
                DarkEnergy::commit(child) # commiting the child after deciding a position
                Parenting::set_objects(stack, child, position) # setting relationship after (!) the two objects are written
                next
            end
            if input == "stack" then
                child = TxStacks::interactivelyMakeOrNull()
                next if child.nil?
                puts JSON.pretty_generate(child)
                position = Parenting::interactivelyDecideRelevantPositionAtCollection(stack)
                DarkEnergy::commit(child) # commiting the child after deciding a position
                Parenting::set_objects(stack, child, position) # setting relationship after (!) the two objects are written
                next
            end
            if input == "destroy" then
                if Parenting::childrenInPositionOrder(stack).empty? then
                    if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction: ") then
                        DarkEnergy::destroy(stack["uuid"])
                        return
                    end
                else
                    puts "Collection needs to be empty to be destroyed"
                    LucilleCore::pressEnterToContinue()
                end
                next
            end
            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end