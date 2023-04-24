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

    # NxBoards::itemsOrdered()
    def self.itemsOrdered()
        NxBoards::items().sort{|i1, i2| TxEngines::completionRatio(i1["engine"]) <=> TxEngines::completionRatio(i2["engine"]) }
    end

    # NxBoards::boardItems(board)
    def self.boardItems(board)
        [
            NxOndates::listingItems(),
            Waves::listingItems(),

            NxFloats::listingItems(),

            NxFires::items(),
            NxCliques::items(),
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

    # NxBoards::listingItems()
    def self.listingItems()
        boards = NxBoards::itemsOrdered()

        cliques = boards
                    .map{|board|
                        cliques1, cliques2 = NxCliques::boardToCliques(board).partition{|clique| clique["active"] }
                        cliques1 = cliques1.sort_by{|clique| TxEngines::completionRatio(clique["engine"]) }
                        cliques2 = cliques2.sort_by{|clique| clique["unixtime"] }
                        cliques1 + cliques2
                    }
                    .flatten

        NxCliques::cliqueToItems(cliques.first) + cliques.drop(1)
    end

    # ---------------------------------------------------------
    # Ops
    # ---------------------------------------------------------

    # NxBoards::interactivelySelectOneBoardOrNull()
    def self.interactivelySelectOneBoardOrNull()
        items = NxBoards::itemsOrdered()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxBoards::toString(item) })
    end

    # NxBoards::interactivelySelectOneBoard()
    def self.interactivelySelectOneBoard()
        loop {
            item = NxBoards::interactivelySelectOneBoardOrNull()
            return item if item
        }
    end

    # NxBoards::interactivelySelectOneCliqueOrNull(board)
    def self.interactivelySelectOneCliqueOrNull(board)
        cliques = NxCliques::boardToCliques(board).sort_by{|clique| clique["unixtime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", cliques, lambda{|item| NxCliques::toString(item) })
    end

    # NxBoards::interactivelySelectOneClique(board)
    def self.interactivelySelectOneClique(board)
        project = NxBoards::interactivelySelectOneCliqueOrNull(board)
        return project if project
        NxBoards::interactivelySelectOneClique(board)
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
                NxBoards::program1(board)
            end
            if action == "holiday" then
                unixtime = CommonUtils::unixtimeAtComingMidnightAtGivenTimeZone(CommonUtils::getLocalTimeZone()) + 3600*3 # 3 am
                if LucilleCore::askQuestionAnswerAsBoolean("> confirm today holiday for '#{PolyFunctions::toString(board).green}': ") then
                    DoNotShowUntil::setUnixtime(board, unixtime)
                end
            end
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
