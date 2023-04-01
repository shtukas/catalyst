class NxBoards

    # --------------------------------------------
    # IO

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

    # --------------------------------------------
    # Makers

    # This can only be called from nslog
    # NxBoards::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        hours = LucilleCore::askQuestionAnswerAsString("hours: ").to_f
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxBoard",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "hours"         => hours,
            "lastResetTime" => 0,
            "capsule"       => SecureRandom.hex
        }
        NxBoards::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxBoards::toString(item)
    def self.toString(item)
        # we use the Board's ow bank account to compute the day completion ratio
        dayTheoreticalInHours = item["hours"].to_f/5
        todayDoneInHours = BankCore::getValueAtDate(item["uuid"], CommonUtils::today()).to_f/3600
        completionRatio = NxBoards::completionRatio(item)
        str0 = "(day: #{("%5.2f" % todayDoneInHours).to_s} of #{"%5.2f" % dayTheoreticalInHours}, cr: #{("%4.2f" % completionRatio).to_s})"

        # but we use the capsule value for the target computations
        capsuleValueInHours = BankCore::getValue(item["capsule"]).to_f/3600
        str1 = "(done #{("%5.2f" % capsuleValueInHours).to_s} out of #{item["hours"]})"

        hasReachedObjective = capsuleValueInHours >= item["hours"]
        timeSinceResetInDays = (Time.new.to_i - item["lastResetTime"]).to_f/86400
        itHassBeenAWeek = timeSinceResetInDays >= 7

        if hasReachedObjective and itHassBeenAWeek then
            str2 = "(awaiting data management)"
        end

        if hasReachedObjective and !itHassBeenAWeek then
            str2 = "(objective met, #{(7 - timeSinceResetInDays).round(2)} days before reset)"
        end

        if !hasReachedObjective and !itHassBeenAWeek then
            str2 = "(#{(7 - timeSinceResetInDays).round(2)} days left in period)"
        end

        if !hasReachedObjective and itHassBeenAWeek then
            str2 = "(late by #{(timeSinceResetInDays-7).round(2)} days)"
        end

        "#{"(board)".green} #{item["description"].ljust(8)} #{str0} #{str1} #{str2}"
    end

    # NxBoards::rtTarget(item)
    def self.rtTarget(item)
        item["hours"].to_f/5 # Hopefully 5 days
    end

    # NxBoards::completionRatio(item)
    def self.completionRatio(item)
        (BankCore::getValueAtDate(item["uuid"], CommonUtils::today()).to_f/3600).to_f/NxBoards::rtTarget(item)
    end

    # NxBoards::boardsOrdered()
    def self.boardsOrdered()
        NxBoards::items().sort{|i1, i2| NxBoards::completionRatio(i1) <=> NxBoards::completionRatio(i2) }
    end

    # ---------------------------------------------------------
    # Ops

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
        boardItems = NxTasks::bItemsOrdered(board)
        return 1 if boardItems.empty?
        boardItems.each{|item| puts NxTasks::toString(item) }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            return boardItems.map{|item| item["position"] }.max + 1
        end
        return position.to_f
    end

    # NxBoards::timeManagement()
    def self.timeManagement()
        return if !Config::isPrimaryInstance()
        NxBoards::items().each{|item|

            # If at time of reset the board's capsule is over flowing, meaning
            # its positive value is more than 50% of the time commitment for the board,
            # meaning we did more than 100% of time commitment then we issue NxTimePromises
            if BankCore::getValue(item["capsule"]) > 1.5*item["hours"]*3600 and (Time.new.to_i - item["lastResetTime"]) >= 86400*7 then
                overflow = 0.5*item["hours"]*3600
                puts "I am about to smooth board: board: #{NxBoards::toString(item)}, overflow: #{(overflow.to_f/3600).round(2)} hours"
                LucilleCore::pressEnterToContinue()
                NxTimePromises::smooth_commit(item["capsule"], -overflow, 20)
                next
                # We need to next because this section would have changed the item
            end

            # We perform a reset, when we have filled the capsule (not to be confused with NxTimePromise)
            # and it's been more than a week. This last condition allows enjoying free time if the capsule was filled quickly.
            if BankCore::getValue(item["capsule"]) >= item["hours"]*3600 and (Time.new.to_i - item["lastResetTime"]) >= 86400*7 then
                puts "I am about to reset board: #{item["description"]}"
                puts "resetting board's capsule time commitment: board: #{NxBoards::toString(item)}, decrease by #{item["hours"]} hours"
                LucilleCore::pressEnterToContinue()
                BankCore::put(item["capsule"], -item["hours"]*3600)
                item["lastResetTime"] = Time.new.to_i
                puts JSON.pretty_generate(item)
                NxBoards::commit(item)
            end
        }
    end

    # NxBoards::informationDisplay(store, boarduuid) 
    def self.informationDisplay(store, boarduuid)
        board = NxBoards::getItemOfNull(boarduuid)
        if board.nil? then
            puts "NxBoards::informationDisplay(boarduuid), board not found"
            exit
        end
        store.register(board, false)
        line = "(#{store.prefixString()}) #{NxBoards::toString(board)}#{DoNotShowUntil::suffixString(board)}#{NxBalls::nxballSuffixStatusIfRelevant(board)}"
        if NxBalls::itemIsRunning(board) or NxBalls::itemIsPaused(board) then
            line = line.green
        end
        puts line
    end

    # NxBoards::listing(board)
    def self.listing(board)

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

            Listing::items(board)
                .flatten
                .each{|item|
                    store.register(item, Listing::canBeDefault(item)) 
                    spacecontrol.putsline(Listing::itemToListingLine(store, item))
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            break if input == ""

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end

    # NxBoards::boardsdive()
    def self.boardsdive()
        board = NxBoards::interactivelySelectOneOrNull()
        return if board.nil?
        NxBoards::listing(board)
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

    # BoardsAndItems::getBoardOrNull(item)
    def self.getBoardOrNull(item)
        return nil if item["boarduuid"].nil?
        NxBoards::getItemFailIfMissing(item["boarduuid"])
    end

    # BoardsAndItems::belongsToThisBoard1(item, board or nil)
    def self.belongsToThisBoard1(item, board)
        if board.nil? then
            item["boarduuid"].nil?
        else
            item["boarduuid"] == board["uuid"]
        end
    end

    # BoardsAndItems::belongsToThisBoard2ForListingManagement(item, board or nil or "all" or "managed")
    def self.belongsToThisBoard2ForListingManagement(item, board)
        if board == "all" then
            return true
        end
        if board == "managed" then
            if NxBoards::completionRatio(board) < 1 then
                return true
            else
                return false
            end
        end
        BoardsAndItems::belongsToThisBoard1(item, board)
    end

    # BoardsAndItems::toStringSuffix(item)
    def self.toStringSuffix(item)
        return "" if item["boarduuid"].nil?
        board = NxBoards::getItemFailIfMissing(item["boarduuid"])
        " (board: #{board["description"].green})"
    end
end
