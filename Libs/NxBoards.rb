class NxBoards

    # ---------------------------------------------------------
    # IO
    # ---------------------------------------------------------

    # NxBoards::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        Solingen::getItemOrNull(uuid)
    end

    # NxBoards::getItemFailIfMissing(uuid)
    def self.getItemFailIfMissing(uuid)
        board = NxBoards::getItemOfNull(uuid)
        return board if board
        raise "looking for a board that should exists. item: #{JSON.pretty_generate(item)}"
    end

    # ---------------------------------------------------------
    # Makers
    # ---------------------------------------------------------

    # This can only be called from nslog
    # NxBoards::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        engine = TxEngines::interactivelyMakeEngineOrDefault()
        Solingen::init("NxBoard", uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "engine", engine)
        Solingen::getItemOrNull(uuid)
    end

    # ---------------------------------------------------------
    # Data
    # ---------------------------------------------------------

    # NxBoards::toString(item)
    def self.toString(item)
        "(#{"boar".green}) #{item["description"]} #{TxEngines::toString(item["engine"])}"
    end

    # NxBoards::boardsOrdered()
    def self.boardsOrdered()
        Solingen::mikuTypeItems("NxBoard").sort_by{|item| TxEngines::completionRatio(item["engine"]) }
    end

    # NxBoards::boardToItems(board)
    def self.boardToItems(board)
        Solingen::mikuTypeItems("NxTask").select{|item| item["boarduuid"] == board["uuid"] }
    end

    # NxBoards::boardToItemsOrdered(board)
    def self.boardToItemsOrdered(board)
        NxBoards::boardToItems(board).sort_by{|item| item["position"] }
    end

    # NxBoards::completionRatio(board)
    def self.completionRatio(board)
        TxEngines::completionRatio(board["engine"])
    end

    # NxBoards::firstItems(board)
    def self.firstItems(board)
        NxBoards::itemsForProgram1(board)
            .select{|item| DoNotShowUntil::isVisible(item) }
            .first(6)
    end

    # ---------------------------------------------------------
    # Selectors
    # ---------------------------------------------------------

    # NxBoards::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxBoards::boardsOrdered()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxBoards::toString(item) })
    end

    # NxBoards::interactivelySelectBoarduuidOrNull()
    def self.interactivelySelectBoarduuidOrNull()
        items = NxBoards::boardsOrdered()
        board = LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxBoards::toString(item) })
        return nil if board.nil?
        board["uuid"]
    end

    # NxBoards::interactivelySelectOneBoard()
    def self.interactivelySelectOneBoard()
        loop {
            item = NxBoards::interactivelySelectOneOrNull()
            return item if item
        }
    end

    # ---------------------------------------------------------
    # Ops
    # ---------------------------------------------------------

    # NxBoards::dataMaintenance()
    def self.dataMaintenance()
        Solingen::mikuTypeItems("NxBoard").each{|board|
            engine2 = TxEngines::engineCarrierMaintenance(board)
            if engine2 then
                Solingen::setAttribute2(board["uuid"], "engine", engine2)
            end
        }
    end

    # ---------------------------------------------------------
    # Programs
    # ---------------------------------------------------------

    # NxBoards::itemsForProgram1(board)
    def self.itemsForProgram1(board)
        [
            NxOndates::listingItems(),
            Solingen::mikuTypeItems("NxFire"),
            Waves::listingItems(board),
            NxBoards::boardToItemsOrdered(board)
        ]
            .flatten
            .select{|item| item["boarduuid"] == board["uuid"] }
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"]}.flatten.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
    end

    # NxBoards::program1(board)
    def self.program1(board)
        loop {

            system("clear")

            puts ""

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            store = ItemStore.new()

            store.register(board, false)
            spacecontrol.putsline(Listing::itemToListingLine(store: store, item: board))
            spacecontrol.putsline ""

            Solingen::mikuTypeItems("NxFloat")
                .select{|item| item["boarduuid"] == board["uuid"] }
                .sort_by{|item| item["unixtime"] }
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    status = spacecontrol.putsline(Listing::itemToListingLine(store: store, item: item))
                    break if !status
                }
            spacecontrol.putsline ""

            items = NxBoards::itemsForProgram1(board)
            items = CommonUtils::putFirst(items, lambda{|item| Listing::isInterruption(item) })
            items = CommonUtils::putFirst(items, lambda{|item| NxBalls::itemIsActive(item) })
            items
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

    # NxBoards::program2(board)
    def self.program2(board)
        loop {
            board = NxBoards::getItemOfNull(board["uuid"])
            return if board.nil?
            puts NxBoards::toString(board)
            actions = ["program(board)", "start", "add time"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            break if action.nil?
            if action == "start" then
                PolyActions::start(board)
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                PolyActions::addTimeToItem(board, timeInHours*3600)
            end
            if action == "program(board)" then
                NxBoards::program1(board)
            end
        }
    end

    # NxBoards::program3()
    def self.program3()
        loop {
            board = NxBoards::interactivelySelectOneOrNull()
            return if board.nil?
            NxBoards::program2(board)
        }
    end
end

class BoardsAndItems

    # BoardsAndItems::attachToItem(item, board or nil)
    def self.attachToItem(item, board)
        return if board.nil?
        Solingen::setAttribute2(item["uuid"], "boarduuid", board["uuid"])
    end

    # BoardsAndItems::maybeAskAndMaybeAttach(item)
    def self.maybeAskAndMaybeAttach(item)
        return if item["boarduuid"]
        BoardsAndItems::askAndMaybeAttach(item)
    end

    # BoardsAndItems::askAndMaybeAttach(item)
    def self.askAndMaybeAttach(item)
        return if item["mikuType"] == "NxBoard"
        if item["mikuType"] == "NxFifo" then
            BoardsAndItems::askAndMaybeAttach(item["payload"])
            return
        end
        board = NxBoards::interactivelySelectOneOrNull()
        return if board.nil?
        Solingen::setAttribute2(item["uuid"], "boarduuid", board["uuid"])
    end

    # BoardsAndItems::toStringSuffix(item)
    def self.toStringSuffix(item)
        return "" if item["boarduuid"].nil?
        board = NxBoards::getItemOfNull(item["boarduuid"])
        if board then
            " (board: #{board["description"].green})"
        else
            " (board: not found, boarduuid: #{item["boarduuid"]})"
        end
    end
end
