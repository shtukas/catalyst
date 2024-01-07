# encoding: UTF-8

class Dives

    # Dives::genericprogram(items)
    def self.genericprogram(items)
        loop {
            system('clear')

            puts ""
            items = items.select{|item| Cubes2::itemOrNull(item["uuid"]) }

            store = ItemStore.new()

            items
                .each{|item|
                    store.register(item, MainUserInterface::canBeDefault(item))
                    puts MainUserInterface::toString2(store, item)
                }

            puts ""
            puts "exit"
            input = LucilleCore::askQuestionAnswerAsString("> ")
            next if input == ""
            return if input == "exit"
            CommandsAndInterpreters::interpreter(input, store)
        }
    end
end
