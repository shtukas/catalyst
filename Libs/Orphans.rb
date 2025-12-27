
class Orphans

    # Orphans::orphans()
    def self.orphans()
        Blades::mikuType("NxTask").select{|item| item["parenting-13"].nil? }
    end

    # Orphans::dive()
    def self.dive()
        loop {
            elements = Orphans::orphans()
            store = ItemStore.new()
            puts ""
            elements
                .each{|item|
                    store.register(item, FrontPage::canBeDefault(item))
                    puts FrontPage::toString2(store, item)
                }
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == "exit"
            return if input == ""

            CommandsAndInterpreters::interpreter(input, store)
        }
    end

end
