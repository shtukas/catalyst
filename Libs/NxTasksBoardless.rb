# encoding: UTF-8

class NxTasksBoardless

    # NxTasksBoardless::items()
    def self.items()
        NxTasks::items()
            .select{|item| item["boarduuid"].nil? }
    end

    # NxTasksBoardless::itemsForListing()
    def self.itemsForListing()
        # {"items", "unixtime"}
        packet = XCache::getOrNull("52b546df-a860-4042-9f92-882ce577b55c")
        if packet then
            packet = JSON.parse(packet)
            if (Time.new.to_i - packet["unixtime"]) < 86400 then
                return packet["items"]
            else
                # will make a new one
            end
        else
            # will make a new one
        end
        puts "> computing new set of boardless items"
        items = NxTasksBoardless::items().first(100)
        packet = { "items" => items, "unixtime" => Time.new.to_i }
        XCache::set("52b546df-a860-4042-9f92-882ce577b55c", JSON.generate(packet))
        items
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
