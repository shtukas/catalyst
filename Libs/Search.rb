class Search

    # Search::run()
    def self.run()
        loop {
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Blades::items_enumerator()
                            .select{|item| item["description"] and item["description"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            lx = lambda { Blades::items_enumerator()
                        .select{|item| item["description"] and item["description"].downcase.include?(fragment.downcase) }
                        .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] } }
            Operations::program3(lx)
        }
        nil
    end
end