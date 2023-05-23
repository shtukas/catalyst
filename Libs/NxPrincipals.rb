class NxPrincipals

    # ---------------------------------------------------------
    # IO
    # ---------------------------------------------------------

    # NxPrincipals::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        Solingen::getItemOrNull(uuid)
    end

    # NxPrincipals::getItemFailIfMissing(uuid)
    def self.getItemFailIfMissing(uuid)
        board = NxPrincipals::getItemOfNull(uuid)
        return board if board
        raise "looking for a board that should exists. item: #{JSON.pretty_generate(item)}"
    end

    # ---------------------------------------------------------
    # Makers
    # ---------------------------------------------------------

    # This can only be called from nslog
    # NxPrincipals::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        engine = TxEngines::interactivelyMakeEngineOrDefault()
        Solingen::init("NxPrincipal", uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "engine", engine)
        Solingen::getItemOrNull(uuid)
    end

    # ---------------------------------------------------------
    # Data
    # ---------------------------------------------------------

    # NxPrincipals::toString(item)
    def self.toString(item)
        "(#{"boar".green}) #{item["description"]} #{TxEngines::toString(item["engine"])}"
    end

    # NxPrincipals::boardsOrdered()
    def self.boardsOrdered()
        Solingen::mikuTypeItems("NxPrincipal").sort_by{|item| TxEngines::dayCompletionRatio(item["engine"]) }
    end

    # NxPrincipals::boardToNxTasks(board)
    def self.boardToNxTasks(board)
        Solingen::mikuTypeItems("NxTask").select{|item| item["parentuuid"] == board["uuid"] }
    end

    # NxPrincipals::boardToNxTasksOrdered(board)
    def self.boardToNxTasksOrdered(board)
        NxPrincipals::boardToNxTasks(board).sort_by{|item| item["position"] }
    end

    # NxPrincipals::boardToNxTasksForListing(board)
    def self.boardToNxTasksForListing(board)
        NxPrincipals::boardToNxTasks(board).sort_by{|item| item["position"] }
    end

    # NxPrincipals::runningItems(board)
    def self.runningItems(board)
        [
            Solingen::mikuTypeItems("NxLine"),
            NxOndates::listingItems(),
            Waves::listingItems(board),
            NxPrincipals::boardToNxTasksForListing(board)
        ]
            .flatten
            .select{|item| NxBalls::itemIsActive(item) }
    end

    # NxPrincipals::boardToThreads(board)
    def self.boardToThreads(board)
        Solingen::mikuTypeItems("NxThread").select{|thread| thread["parentuuid"] == board["uuid"] }
    end

    # ---------------------------------------------------------
    # Selectors
    # ---------------------------------------------------------

    # NxPrincipals::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = NxPrincipals::boardsOrdered()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxPrincipals::toString(item) })
    end

    # NxPrincipals::interactivelySelectBoarduuidOrNull()
    def self.interactivelySelectBoarduuidOrNull()
        items = NxPrincipals::boardsOrdered()
        board = LucilleCore::selectEntityFromListOfEntitiesOrNull("board", items, lambda{|item| NxPrincipals::toString(item) })
        return nil if board.nil?
        board["uuid"]
    end

    # NxPrincipals::interactivelySelectOneBoard()
    def self.interactivelySelectOneBoard()
        loop {
            item = NxPrincipals::interactivelySelectOneOrNull()
            return item if item
        }
    end

    # ---------------------------------------------------------
    # Ops
    # ---------------------------------------------------------

    # NxPrincipals::dataMaintenance()
    def self.dataMaintenance()
        Solingen::mikuTypeItems("NxPrincipal").each{|board|
            engine2 = TxEngines::engineCarrierMaintenance(board)
            if engine2 then
                Solingen::setAttribute2(board["uuid"], "engine", engine2)
            end
        }
    end

    # ---------------------------------------------------------
    # Programs
    # ---------------------------------------------------------

    # NxPrincipals::itemsForBoardListing(board)
    def self.itemsForBoardListing(board)
        [
            Solingen::mikuTypeItems("NxBurner"),
            Solingen::mikuTypeItems("NxLine"),
            Solingen::mikuTypeItems("NxFire"),
            NxOndates::listingItems(),
            Waves::listingItems(board),
            NxPrincipals::boardToNxTasksForListing(board),
            NxPrincipals::boardToThreads(board)
        ]
            .flatten
            .select{|item| (item["parentuuid"] == board["uuid"]) or NxBalls::itemIsActive(item) }
            .reduce([]){|selected, item|
                if selected.map{|i| i["uuid"]}.flatten.include?(item["uuid"]) then
                    selected
                else
                    selected + [item]
                end
            }
    end

    # NxPrincipals::boardListing(board)
    def self.boardListing(board)
        loop {

            system("clear")

            puts ""

            spacecontrol = SpaceControl.new(CommonUtils::screenHeight() - 4)

            store = ItemStore.new()

            store.register(board, false)
            spacecontrol.putsline(Listing::itemToListingLine(store: store, item: board))
            spacecontrol.putsline ""

            NxPrincipals::itemsForBoardListing(board)
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    status = spacecontrol.putsline(Listing::itemToListingLine(store: store, item: item))
                    break if !status
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end

    # NxPrincipals::program2(board)
    def self.program2(board)
        loop {
            board = NxPrincipals::getItemOfNull(board["uuid"])
            return if board.nil?
            puts NxPrincipals::toString(board)
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
                NxPrincipals::boardListing(board)
            end
        }
    end

    # NxPrincipals::program3()
    def self.program3()
        loop {
            board = NxPrincipals::interactivelySelectOneOrNull()
            return if board.nil?
            NxPrincipals::program2(board)
        }
    end
end

class BoardsAndItems

    # BoardsAndItems::attachToItem(item, board or nil)
    def self.attachToItem(item, board)
        return if board.nil?
        Solingen::setAttribute2(item["uuid"], "parentuuid", board["uuid"])
    end

    # BoardsAndItems::maybeAskAndMaybeAttach(item)
    def self.maybeAskAndMaybeAttach(item)
        return if item["parentuuid"]
        BoardsAndItems::askAndMaybeAttach(item)
    end

    # BoardsAndItems::askAndMaybeAttach(item)
    def self.askAndMaybeAttach(item)
        return if item["mikuType"] == "NxPrincipal"
        board = NxPrincipals::interactivelySelectOneOrNull()
        return if board.nil?
        Solingen::setAttribute2(item["uuid"], "parentuuid", board["uuid"])
    end

    # BoardsAndItems::toStringSuffix(item)
    def self.toStringSuffix(item)
        return "" if item["parentuuid"].nil?
        parent = NxPrincipals::getItemOfNull(item["parentuuid"])
        if parent then
            " (parent: #{parent["description"].green})"
        else
            " (parent: not found, parentuuid: #{item["parentuuid"]})"
        end
    end
end
