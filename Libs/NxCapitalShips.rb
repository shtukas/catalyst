class NxCapitalShips

    # ---------------------------------------------------------
    # IO
    # ---------------------------------------------------------

    # NxCapitalShips::items()
    def self.items()
        N3Objects::getMikuType("NxCapitalShip")
    end

    # NxCapitalShips::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        N3Objects::getOrNull(uuid)
    end

    # NxCapitalShips::getItemFailIfMissing(uuid)
    def self.getItemFailIfMissing(uuid)
        board = NxCapitalShips::getItemOfNull(uuid)
        return board if board
        raise "looking for a board that should exists. item: #{JSON.pretty_generate(item)}"
    end

    # NxCapitalShips::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # ---------------------------------------------------------
    # Makers
    # ---------------------------------------------------------

    # This can only be called from nslog
    # NxCapitalShips::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxCapitalShip",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "engine"        => TxEngines::interactivelyMakeEngineOrNull()
        }
        NxCapitalShips::commit(item)
        item
    end

    # ---------------------------------------------------------
    # Data
    # ---------------------------------------------------------

    # NxCapitalShips::toString(item)
    def self.toString(item)
        "#{"(board)".green} #{item["description"]} #{TxEngines::toString(item["engine"])}"
    end

    # NxCapitalShips::itemsOrdered()
    def self.itemsOrdered()
        NxCapitalShips::items().sort{|i1, i2| TxEngines::completionRatio(i1["engine"]) <=> TxEngines::completionRatio(i2["engine"]) }
    end

    # NxCapitalShips::listingItems()
    def self.listingItems()
        NxCapitalShips::items()
            .map{|item| TxEngines::engineMaintenanceOrNothing(item) }
            .select{|board| NxCapitalShips::boardItems(board).empty? or NxBalls::itemIsRunning(board) }
            .select{|board| TxEngines::completionRatio(board["engine"]) < 1 or NxBalls::itemIsRunning(board) }
    end

    # NxCapitalShips::boardItems(board)
    def self.boardItems(board)
        [
            NxOndates::listingItems(),
            Waves::listingItems(),

            NxFloats::listingItems(),

            NxFires::items(),
            PriorityItems::listingItems(),
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

    # NxCapitalShips::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxCapitalShips::itemsOrdered()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxCapitalShips::toString(item) })
    end

    # NxCapitalShips::interactivelySelectOne()
    def self.interactivelySelectOne()
        loop {
            item = NxCapitalShips::interactivelySelectOneOrNull()
            return item if item
        }
    end

    # NxCapitalShips::interactivelyDecideNewBoardPosition(board)
    def self.interactivelyDecideNewBoardPosition(board)
        boardItems = NxTasks::boardItemsOrdered(board)
        return 1 if boardItems.empty?
        boardItems.take(CommonUtils::screenHeight()-3).each{|item| puts NxTasks::toString(item) }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            return boardItems.map{|item| item["position"] }.max + 1
        end
        return position.to_f
    end

    # ---------------------------------------------------------
    # Programs
    # ---------------------------------------------------------

    # NxCapitalShips::program1(board)
    def self.program1(board)

        loop {

            system("clear")

            puts ""

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            store = ItemStore.new()

            store.register(board, false)
            line = "(#{store.prefixString()}) #{NxCapitalShips::toString(board)}#{NxBalls::nxballSuffixStatusIfRelevant(board)}"
            if NxBalls::itemIsActive(board) then
                line = line.green
            end
            spacecontrol.putsline line

            spacecontrol.putsline ""

            NxCapitalShips::boardItems(board)
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

    # NxCapitalShips::program2(board)
    def self.program2(board)
        loop {
            board = NxCapitalShips::getItemOfNull(board["uuid"])
            return if board.nil?
            puts NxCapitalShips::toString(board)
            actions = ["program(board)", "start", "add time", "holiday"]
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
                NxCapitalShips::program1(board)
            end
            if action == "holiday" then
                unixtime = CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) + 3600*3 # 3 am
                if LucilleCore::askQuestionAnswerAsBoolean("> confirm today holiday for '#{PolyFunctions::toString(board).green}': ") then
                    DoNotShowUntil::setUnixtime(board, unixtime)
                end
            end
        }
    end

    # NxCapitalShips::program3()
    def self.program3()
        loop {
            board = NxCapitalShips::interactivelySelectOneOrNull()
            return if board.nil?
            NxCapitalShips::program2(board)
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
        return item if item["mikuType"] == "NxCapitalShip"
        return item if item["boarduuid"]
        board = NxCapitalShips::interactivelySelectOneOrNull()
        return item if board.nil?
        item["boarduuid"] = board["uuid"]
        N3Objects::commit(item)
        item
    end

    # PlanetsAndItems::askAndMaybeAttach(item)
    def self.askAndMaybeAttach(item)
        return item if item["mikuType"] == "NxCapitalShip"
        board = NxCapitalShips::interactivelySelectOneOrNull()
        return item if board.nil?
        item["boarduuid"] = board["uuid"]
        N3Objects::commit(item)
        item
    end

    # PlanetsAndItems::toStringSuffix(item)
    def self.toStringSuffix(item)
        return "" if item["boarduuid"].nil?
        board = NxCapitalShips::getItemOfNull(item["boarduuid"])
        if board then
            " (board: #{board["description"].green})"
        else
            " (board: not found, boarduuid: #{item["boarduuid"]})"
        end
    end
end
