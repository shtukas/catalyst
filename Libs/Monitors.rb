
class Monitors

    # Monitors::monitorToRunningItems(monitor)
    # Monitors are either: NxBoard, NxBoard,
    def self.monitorToRunningItems(monitor)
        if monitor["mikuType"] == "NxBoard" then
            return NxBoards::runningItems(monitor)
        end
        if monitor["mikuType"] == "NxMonitorLongs" then
            return Solingen::mikuTypeItems("NxLong")
                    .select{|item| NxBalls::itemIsActive(item) }
        end
        if monitor["mikuType"] == "NxMonitorTasksBoardless" then
            return NxTasks::boardlessItems()
                .sort_by{|item| item["position"] }
                .take(16)
                .select{|item| NxBalls::itemIsActive(item) }
        end
        raise "(error: 580b9d54-07a5-479b-aeef-cd5e2c1c6e35) I do not know how to Monitors::monitorToRunningItems((#{JSON.pretty_generate(monitor)}, size)"
    end

    # Monitors::dayCompletionRatio(monitor)
    def self.dayCompletionRatio(monitor)
        if monitor["mikuType"] == "NxBoard" then
            return TxEngines::dayCompletionRatio(monitor["engine"])
        end
        if monitor["mikuType"] == "NxMonitorLongs" then
            return TxEngines::dayCompletionRatio(monitor["engine"])
        end
        if monitor["mikuType"] == "NxMonitorTasksBoardless" then
            return TxEngines::dayCompletionRatio(monitor["engine"])
        end
        raise "(error: b31c7245-31cd-4546-8eac-1803ef843801) could not compute day completion ratio for monitor: #{monitor}"
    end

    # Monitors::periodCompletionRatio(monitor)
    def self.periodCompletionRatio(monitor)
        if monitor["mikuType"] == "NxBoard" then
            return TxEngines::periodCompletionRatio(monitor["engine"])
        end
        if monitor["mikuType"] == "NxMonitorLongs" then
            return TxEngines::periodCompletionRatio(monitor["engine"])
        end
        if monitor["mikuType"] == "NxMonitorTasksBoardless" then
            return TxEngines::periodCompletionRatio(monitor["engine"])
        end
        raise "(error: b31c7245-31cd-4546-8eac-1803ef843801) could not compute period completion ratio for monitor: #{monitor}"
    end

    # Monitors::listingOrderingRatio(engine)
    def self.listingOrderingRatio(engine)
        0.9*Monitors::dayCompletionRatio(engine) + 0.1*Monitors::periodCompletionRatio(engine)
    end

    # Monitors::program()
    def self.program()
        loop {

            system("clear")

            puts ""

            store = ItemStore.new()

            (Solingen::mikuTypeItems("NxBoard") + Solingen::mikuTypeItems("NxMonitorLongs") + Solingen::mikuTypeItems("NxMonitorTasksBoardless"))
                .sort_by{|item| Monitors::periodCompletionRatio(item) }
                .each{|item|
                    store.register(item, false)
                    line = Listing::itemToListingLine(store: store, item: item)
                    puts line
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end
end
