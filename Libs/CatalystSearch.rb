class CatalystSearch

    # CatalystSearch::run()
    def self.run()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Catalyst::catalystItems()
                            .select{|item| item["description"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = Catalyst::catalystItems()
                                .select{|item| item["description"].downcase.include?(fragment.downcase) }
                                .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|i| i["description"] })
                break if item.nil?
                PolyActions::program(item)
            }
        }
        nil
    end
end