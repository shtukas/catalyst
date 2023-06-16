
class TxStacks

    # TxStacks::interactivelyMakeOrNull()
    def self.interactivelyMakeOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "TxStack",
            "unixtime"    => Time.new.to_f,
            "datetime"    => Time.new.utc.iso8601,
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
         "👨🏻‍💻 (stack)#{TxStacks::positionsuffix(item)} #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # TxStacks::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        stacks = DarkEnergy::mikuType("NxStack")
        LucilleCore::selectEntityFromListOfEntitiesOrNull("stack", stacks, lambda{|item| item["description"] })
    end

    # TxStacks::interactivelySelectPosition(stack)
    def self.interactivelySelectPosition(stack)
        puts TxStacks::toString(stack).green
        TxStacks::children_ordered(stack).each{|item|
            puts "    - #{TxStacks::toString(item)}"
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
            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            puts ""
            spacecontrol.putsline "@stack:"
            store.register(stack, false)
            puts Listing::itemToListingLine(store, stack)

            puts ""
            TxStacks::children_ordered(stack)
                .each{|item|
                    store.register(item, false)
                    puts Listing::itemToListingLine(store, item)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
        }
    end

    # TxStacks::program0()
    def self.program0()
        loop {
            stacks = DarkEnergy::mikuType("TxStack")
            if stacks.empty? then
                puts "no stack found"
                LucilleCore::pressEnterToContinue()
                return
            end
            stack = LucilleCore::selectEntityFromListOfEntitiesOrNull("stack", stacks, lambda{|stack| TxStacks::toString(stack) })
            return if stack.nil?
            TxStacks::program(stack)
        }
    end

    # TxStacks::getItemStackOrNull(item)
    def self.getItemStackOrNull(item)
        return nil if item["nsstack1130"].nil?
        DarkEnergy::itemOrNull(item["nsstack1130"]["uuid"])
    end

    # TxStacks::suffix(item)
    def self.suffix(item)
        stack = TxStacks::getItemStackOrNull(item)
        return "" if stack.nil?
        " (stack: #{stack["description"]})".green
    end

    # TxStacks::positionsuffix(item)
    def self.positionsuffix(item)
        return "" if item["nsstack1130"].nil?
        " (#{item["nsstack1130"]["position"]})".green
    end

    # TxStacks::interactivelyUpdatePositionAtSameStack(item)
    def self.interactivelyUpdatePositionAtSameStack(item)
        return if item["nsstack1130"].nil?
        stack = DarkEnergy::itemOrNull(item["nsstack1130"]["uuid"])
        return if stack.nil?
        position = TxStacks::interactivelySelectPosition(stack)
        item["nsstack1130"]["position"] = position
        DarkEnergy::commit(item)
    end

    # TxStacks::children_ordered(stack)
    def self.children_ordered(stack)
        DarkEnergy::all()
            .select{|item| item["nsstack1130"]["uuid"] == stack["uuid"] }
            .sort_by{|item| item["nsstack1130"]["position"] }
    end
end

