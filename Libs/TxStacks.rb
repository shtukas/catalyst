
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
        position = NxTasks::getItemPositionOrNull(item)
        if position then
            "👨🏻‍💻 (#{"%5.2f" % position}) #{item["description"]}"
        else
            "👨🏻‍💻 (missing position) #{item["description"]}"
        end
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
            puts Listing::itemToListingLine(store, stack)

            Parenting::children_ordered(stack)
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
                position = TxStacks::interactivelySelectPosition(stack)
                Parenting::set_objects(stack, child, position)
                next
            end
            if input == "pool" then
                child = TxPools::interactivelyMakeOrNull()
                next if child.nil?
                position = TxStacks::interactivelySelectPosition(stack)
                Parenting::set_objects(stack, child, position)
                next
            end
            if input == "stack" then
                child = TxStacks::interactivelyMakeOrNull()
                next if child.nil?
                position = TxStacks::interactivelySelectPosition(stack)
                Parenting::set_objects(stack, child, position)
                next
            end

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end