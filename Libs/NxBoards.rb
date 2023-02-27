
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
        dayLoadInHours = item["hours"].to_f/5
        dayDoneInHours = BankCore::getValueAtDate(item["uuid"], CommonUtils::today()).to_f/3600
        completionRatio = NxBoards::completionRatio(item)
        str0 = "(day: #{("%5.2f" % dayDoneInHours).to_s.green} of #{"%5.2f" % dayLoadInHours}, cr: #{("%4.2f" % completionRatio).to_s.green})"

        loadDoneInHours = BankCore::getValue(item["capsule"]).to_f/3600 + item["hours"]
        loadLeftInhours = item["hours"] - loadDoneInHours
        str1 = "(done #{("%5.2f" % loadDoneInHours).to_s.green} out of #{item["hours"]})"

        timePassedInDays = (Time.new.to_i - item["lastResetTime"]).to_f/86400
        timeLeftInDays = 7 - timePassedInDays
        str2 = 
            if timeLeftInDays > 0 then
                "(#{timeLeftInDays.round(2)} days before reset)"
            else
                "(late by #{-timeLeftInDays.round(2)} days)"
            end

        "(board) #{item["description"].ljust(8)} #{str0} #{str1} #{str2}"
    end

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
        boardItems = NxHeads::bItemsOrdered(board["uuid"])
        return 1 if boardItems.empty?
        boardItems
            .first(20)
            .each{|item| puts NxHeads::toString(item) }
        loop {
            position = LucilleCore::askQuestionAnswerAsString("position: ")
            next if position == ""
            return position.to_f
        }
    end

    # NxBoards::rtTarget(item)
    def self.rtTarget(item)
        item["hours"].to_f/5 # Hopefully 5 days
    end

    # NxBoards::completionRatio(item)
    def self.completionRatio(item)
        BankUtils::recoveredAverageHoursPerDay(item["uuid"]).to_f/NxBoards::rtTarget(item)
    end

    # NxBoards::listingItems()
    def self.listingItems()
        NxBoards::items()
            .map {|board|
                {
                    "board" => board,
                    "cr"    => NxBoards::completionRatio(board)
                }
            }
            .select{|packet| packet["cr"] < 1 or NxBalls::itemIsActive(packet["board"]) }
            .sort{|p1, p2| p1["cr"] <=> p2["cr"] }
            .map {|packet| packet["board"] }
    end

    # NxBoards::bottomItems()
    def self.bottomItems()
        NxBoards::items()
            .select{|board| !NxBalls::itemIsActive(board) }
            .map {|board|
                {
                    "board" => board,
                    "cr"    => NxBoards::completionRatio(board)
                }
            }
            .sort{|p1, p2| p1["cr"] <=> p2["cr"] }
            .map {|packet| packet["board"] }
    end

    # NxBoards::boardsOrdered()
    def self.boardsOrdered()
        NxBoards::items().sort{|i1, i2| NxBoards::completionRatio(i1) <=> NxBoards::completionRatio(i2) }
    end

    # ---------------------------------------------------------
    # Ops

    # NxBoards::timeManagement()
    def self.timeManagement()
        NxBoards::items().each{|item|

            # If the board's capsule is over flowing, meaning its positive value is moer than 50% of the time commitment for the board
            # Meaning we did more than 100% of time commitment then we issue NxTimeCapsules
            if BankCore::getValue(item["capsule"]) >= 0.5*item["hours"]*3600 then
                puts "NxBoards::timeManagement(), code to be written"
                exit
            end

            # We perform a reset, when we have filled the capsule (not to be confused with NxTimeCapsule)
            # and it's been more than a week. This last condition allows enjoying free time if the capsule was filled quickly.
            if BankCore::getValue(item["capsule"]) >= 0 and (Time.new.to_i - item["lastResetTime"]) >= 86400*7 then
                puts "resetting board's capsule time commitment: #{item["description"]}"
                BankCore::put(item["capsule"], -item["hours"]*3600)
                item["lastResetTime"] = Time.new.to_i
                NxBoards::commit(item)
            end
        }
    end

    # NxBoards::listingDisplay(store, spacecontrol, boarduuid) 
    def self.listingDisplay(store, spacecontrol, boarduuid)
        board = NxBoards::getItemOfNull(boarduuid)

        if board.nil? then
            puts "NxBoards::listingDisplay(boarduuid), board not found"
            exit
        end

        tops = NxTops::itemsInOrder().select{|item|
            (lambda{
                bx = N2KVStore::getOrNull("BoardsAndItems:#{item["uuid"]}")
                return false if bx.nil?
                return false if bx["uuid"] != boarduuid
                true
            }).call()
        }

        ondates = NxOndates::listingItems(board)

        waves = Waves::items()
            .select{|item|
                (lambda{
                    bx = N2KVStore::getOrNull("BoardsAndItems:#{item["uuid"]}")
                    return false if bx.nil?
                    return false if bx["uuid"] != boarduuid
                    true
                }).call()
            }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) or NxBalls::itemIsActive(item["uuid"]) }

        items = NxHeads::bItemsOrdered(board["uuid"])

        store.register(board, (tops+waves+items).empty?)
        line = "(#{store.prefixString()}) #{NxBoards::toString(board)}#{NxBalls::nxballSuffixStatusIfRelevant(board)}"
        if NxBalls::itemIsRunning(board) or NxBalls::itemIsPaused(board) then
            line = line.green
        end
        spacecontrol.putsline line
        NxFloats::listingItems(boarduuid).each{|item|
            store.register(item, false)
            spacecontrol.putsline "(#{store.prefixString()}) (float) #{item["description"]}"
        }

        lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }

        lockedItems
            .each{|item|
                store.register(item, false)
                spacecontrol.putsline (Listing::itemToListingLine(store, item))
            }

        tops.each{|item|
            next if !DoNotShowUntil::isVisible(item["uuid"]) and !NxBalls::itemIsRunning(item["uuid"])
            store.register(item, true)
            spacecontrol.putsline (Listing::itemToListingLine(store, item))
        }

        ondates.each{|item|
            next if !DoNotShowUntil::isVisible(item["uuid"]) and !NxBalls::itemIsRunning(item["uuid"])
            store.register(item, true)
            spacecontrol.putsline (Listing::itemToListingLine(store, item))
        }

        waves.each{|item|
            next if !DoNotShowUntil::isVisible(item["uuid"]) and !NxBalls::itemIsRunning(item["uuid"])
            store.register(item, true)
            spacecontrol.putsline (Listing::itemToListingLine(store, item))
        }

        items.take(6)
            .each{|item|
                next if !DoNotShowUntil::isVisible(item["uuid"]) and !NxBalls::itemIsRunning(item["uuid"])
                store.register(item, true)
                spacecontrol.putsline (Listing::itemToListingLine(store, item))
            }
    end

    # NxBoards::bottomDisplay(store, spacecontrol, boarduuid) 
    def self.bottomDisplay(store, spacecontrol, boarduuid)
        board = NxBoards::getItemOfNull(boarduuid)
        padding = "      "
        if board.nil? then
            puts "NxBoards::bottomDisplay(boarduuid), board not found"
            exit
        end
        store.register(board, false)
        line = "(#{store.prefixString()}) #{NxBoards::toString(board)}#{DoNotShowUntil::suffixString(board)}#{NxBalls::nxballSuffixStatusIfRelevant(board)}"
        if NxBalls::itemIsRunning(board) or NxBalls::itemIsPaused(board) then
            line = line.green
        end
        spacecontrol.putsline line
    end
end

class BoardsAndItems

    # BoardsAndItems::attachToItem(item, board or nil)
    def self.attachToItem(item, board)
        return if board.nil?
        item["boarduuid"] = board["uuid"]
        N3Objects::commit(item)
    end

    # BoardsAndItems::interactivelyOffersToAttach(item)
    def self.interactivelyOffersToAttach(item)
        return nil if item["boarduuid"]
        return nil if item["mikuType"] == "NxBoard"
        if item["mikuType"] == "NxProject" then
            puts "> NxProjects cannot be boarded"
            LucilleCore::pressEnterToContinue()
            return
        end
        board = NxBoards::interactivelySelectOneOrNull()
        return nil if board.nil?
        item["boarduuid"] = board["uuid"]
        N3Objects::commit(item)
        board
    end

    # BoardsAndItems::getBoardOrNull(item)
    def self.getBoardOrNull(item)
        return nil if item["boarduuid"].nil?
        NxBoards::getItemFailIfMissing(item["boarduuid"])
    end

    # BoardsAndItems::belongsToThisBoard(item, board or nil)
    def self.belongsToThisBoard(item, board)
        if board.nil? then
            item["boarduuid"].nil?
        else
            item["boarduuid"] == board["uuid"]
        end
    end

    # BoardsAndItems::toStringSuffix(item)
    def self.toStringSuffix(item)
        return "" if item["boarduuid"].nil?
        board = NxBoards::getItemFailIfMissing(item["boarduuid"])
        " (board: #{board["description"]})".green
    end

end
