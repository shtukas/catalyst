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
            "engine"        => TxEngines::interactivelyMakeEngineOrDefault()
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
        NxBoards::items().sort{|i1, i2| TxEngines::completionRatio(i1["engine"]) <=> TxEngines::completionRatio(i2["engine"]) }
    end

    # NxBoards::boardToItems(board)
    def self.boardToItems(board)
        NxTasks::items().select{|item| item["boarduuid"] == board["uuid"] }
    end

    # NxBoards::boardToItemsOrdered(board)
    def self.boardToItemsOrdered(board)
        NxBoards::boardToItems(board).sort_by{|item| item["position"] }
    end

    # ---------------------------------------------------------
    # Ops
    # ---------------------------------------------------------

    # NxBoards::interactivelySelectOneBoardOrNull()
    def self.interactivelySelectOneBoardOrNull()
        items = NxBoards::boardsOrdered()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxBoards::toString(item) })
    end

    # NxBoards::interactivelySelectOneBoard()
    def self.interactivelySelectOneBoard()
        loop {
            item = NxBoards::interactivelySelectOneBoardOrNull()
            return item if item
        }
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
            spacecontrol.putsline(Listing::itemToListingLine(store, board))
            spacecontrol.putsline ""

            NxFloats::items()
                .select{|item| item["boarduuid"] == board["uuid"] }
                .sort_by{|item| item["unixtime"] }
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    status = spacecontrol.putsline(Listing::itemToListingLine(store, item))
                    break if !status
                }
            spacecontrol.putsline ""

            items = [
                NxOndates::listingItems(),
                Waves::listingItems(),
                NxFloats::items().sort_by{|item| item["unixtime"] },
                NxFires::items(),
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

            items = CommonUtils::putFirst(items, lambda{|item| Listing::isInterruption(item) })
            items = CommonUtils::putFirst(items, lambda{|item| NxBalls::itemIsActive(item) })

            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    status = spacecontrol.putsline(Listing::itemToListingLine(store, item))
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
            actions = ["program(board)", "start", "add time", "do not show until"]
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
            if action == "do not show until" then
                unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
                if unixtime then
                    DoNotShowUntil::setUnixtime(board, unixtime)
                end
            end
        }
    end

    # NxBoards::program3()
    def self.program3()
        loop {
            board = NxBoards::interactivelySelectOneBoardOrNull()
            return if board.nil?
            NxBoards::program2(board)
        }
    end
end

class PlanetsAndItems

    # PlanetsAndItems::attachToItem(item, board or nil)
    def self.attachToItem(item, board)
        return if board.nil?
        item["boarduuid"] = board["uuid"]
        N3Objects::commit(item)
    end

    # PlanetsAndItems::maybeAskAndMaybeAttach(item)
    def self.maybeAskAndMaybeAttach(item)
        return item if item["mikuType"] == "NxBoard"
        return item if item["boarduuid"]
        board = NxBoards::interactivelySelectOneBoardOrNull()
        return item if board.nil?
        item["boarduuid"] = board["uuid"]
        N3Objects::commit(item)
        item
    end

    # PlanetsAndItems::askAndMaybeAttach(item)
    def self.askAndMaybeAttach(item)
        return item if item["mikuType"] == "NxBoard"
        board = NxBoards::interactivelySelectOneBoardOrNull()
        return item if board.nil?
        item["boarduuid"] = board["uuid"]
        N3Objects::commit(item)
        item
    end

    # PlanetsAndItems::toStringSuffix(item)
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
