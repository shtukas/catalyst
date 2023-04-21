class NxBoards

    # ---------------------------------------------------------
    # IO
    # ---------------------------------------------------------

    # NxBoards::items()
    def self.items()
        N3Objects::getMikuType("NxBoard")
    end

    # NxBoards::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        N3Objects::getOrNull(uuid)
    end

    # NxBoards::getItemFailIfMissing(uuid)
    def self.getItemFailIfMissing(uuid)
        board = NxBoards::getItemOfNull(uuid)
        return board if board
        raise "looking for a board that should exists. item: #{JSON.pretty_generate(item)}"
    end

    # NxBoards::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
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
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxBoard",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "engine"        => TxEngines::interactivelyMakeEngineOrNull()
        }
        NxBoards::commit(item)
        item
    end

    # ---------------------------------------------------------
    # Data
    # ---------------------------------------------------------

    # NxBoards::toString(item)
    def self.toString(item)
        "#{"(board)".green} #{item["description"]} #{TxEngines::toString(item["engine"])}"
    end

    # NxBoards::boardsOrdered()
    def self.boardsOrdered()
        NxBoards::items().sort{|i1, i2| TxEngines::completionRatio(i2["engine"]) <=> TxEngines::completionRatio(i2["engine"]) }
    end

    # NxBoards::listingItems()
    def self.listingItems()
        NxBoards::items()
            .map{|item| TxEngines::engineMaintenanceOrNothing(item) }
            .select{|board| NxBoards::boardItems(board).empty? or NxBalls::itemIsRunning(board) }
            .select{|board| TxEngines::completionRatio(board["engine"]) < 1 or NxBalls::itemIsRunning(board) }
    end

    # NxBoards::boardItems(board)
    def self.boardItems(board)
        [
            NxFires::items(),
            NxOndates::listingItems(),
            Waves::listingItems(),
            NxFloats::listingItems(),
            NxTasks::listingItemsPriority(),
            NxCliques::listingItems(),
            NxTasks::boardItemsOrdered(board),
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

    # ---------------------------------------------------------
    # Ops
    # ---------------------------------------------------------

    # NxBoards::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxBoards::items()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxBoards::toString(item) })
    end

    # NxBoards::interactivelySelectOne()
    def self.interactivelySelectOne()
        loop {
            item = NxBoards::interactivelySelectOneOrNull()
            return item if item
        }
    end

    # NxBoards::interactivelyDecideNewBoardPosition(board)
    def self.interactivelyDecideNewBoardPosition(board)
        boardItems = NxTasks::boardItemsOrdered(board)
        return 1 if boardItems.empty?
        boardItems.each{|item| puts NxTasks::toString(item) }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            return boardItems.map{|item| item["position"] }.max + 1
        end
        return position.to_f
    end

    # ---------------------------------------------------------
    # Programs
    # ---------------------------------------------------------

    # NxBoards::program1(board)
    def self.program1(board)

        loop {

            system("clear")

            puts ""

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            store = ItemStore.new()

            store.register(board, false)
            line = "(#{store.prefixString()}) #{NxBoards::toString(board)}#{NxBalls::nxballSuffixStatusIfRelevant(board)}"
            if NxBalls::itemIsActive(board) then
                line = line.green
            end
            spacecontrol.putsline line

            spacecontrol.putsline ""

            NxBoards::boardItems(board)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    spacecontrol.putsline(Listing::itemToListingLine(store, item))
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
        item["boarduuid"] = board["uuid"]
        N3Objects::commit(item)
    end

    # BoardsAndItems::askAndMaybeAttach(item)
    def self.askAndMaybeAttach(item)
        return item if item["boarduuid"]
        return item if item["mikuType"] == "NxBoard"
        board = NxBoards::interactivelySelectOneOrNull()
        return item if board.nil?
        item["boarduuid"] = board["uuid"]
        N3Objects::commit(item)
        item
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
