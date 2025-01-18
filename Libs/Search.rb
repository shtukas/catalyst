class Search

    # Search::run()
    def self.run()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Items::items()
                            .select{|item| item["description"] and item["description"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            selected = Items::items()
                        .select{|item| item["description"] and item["description"].downcase.include?(fragment.downcase) }
                        .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            Operations::program2(selected)
        }
        nil
    end
end