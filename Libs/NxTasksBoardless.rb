# encoding: UTF-8

class NxTasksBoardless

    # NxTasksBoardless::items()
    def self.items()
        NxTasks::items()
            .select{|item| item["boarduuid"].nil? }
    end

    # NxTasksBoardless::itemIsBoardlessTask(item)
    def self.itemIsBoardlessTask(item)
        return false if item["mikuType"] != "NxTask"
        return false if item["boarduuid"]
        true
    end

    # NxTasksBoardless::program1()
    def self.program1()
        loop {

            system("clear")

            puts ""

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            store = ItemStore.new()

            NxTasksBoardless::items()
                .sort_by{|item| item["position"] }
                .take(CommonUtils::screenHeight()-5)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    status = spacecontrol.putsline(Listing::itemToListingLine(store: store, item: item))
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end
end
