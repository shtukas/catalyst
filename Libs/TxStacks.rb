
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

    # TxStacks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        stack = TxStacks::interactivelyMakeOrNull()
        DarkEnergy::commit(stack)
        stack
    end

    # TxStacks::toString(item)
    def self.toString(item)
         "👨🏻‍💻 (stack)#{Parenting::positionSuffix(item)} #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # TxStacks::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        stacks = DarkEnergy::mikuType("NxStack")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("stack", stacks, lambda{|item| item["description"] })
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

    # TxStacks::program(stack)
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
            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end

