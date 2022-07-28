
# encoding: UTF-8

class Search

    # ---------------------------

    # Search::interativeInterfaceSelectNx20OrNull()
    def self.interativeInterfaceSelectNx20OrNull()
        CommonUtils::selectOneObjectUsingInteractiveInterfaceOrNull(Nx20s::nx20s(), lambda{|item| item["announce"].downcase })
    end

    # Search::interativeInterface()
    def self.interativeInterface()
        loop {
            nx20 = Search::interativeInterfaceSelectNx20OrNull()
            break if nx20.nil?
            item = Fx18::itemOrNull(nx20["objectuuid"])
            LxAction::action("landing", item)
        }
    end

    # ---------------------------

    # Search::classicInterface()
    def self.classicInterface()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Nx20s::nx20s()
                .select{|nx20| !nx20["announce"].nil? }
                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = Nx20s::nx20s()
                    .select{|nx20| !nx20["announce"].nil? }
                    .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|item| item["announce"] })
                break if nx20.nil?
                system('clear')
                item = Fx18::itemOrNull(nx20["objectuuid"])
                LxAction::action("landing", item)
            }
        }
    end

    # ---------------------------
end
