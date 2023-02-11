
class NxBoards

    # NxBoards::items()
    def self.items()
        ObjectStore2::objects("NxBoards")
    end

    # NxBoards::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        ObjectStore2::getOrNull("NxBoards", uuid)
    end

    # NxBoards::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxBoards", item)
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
            "uuid"        => uuid,
            "mikuType"    => "NxBoard",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "hours"       => hours
        }
        NxBoards::commit(item)
        item
    end

    # NxBoards::issueLine(line, boarduuid, boardposition)
    def self.issueLine(line, boarduuid, boardposition)
        description = line
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxBoardItem",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => nil,
            "boarduuid"     => boarduuid,
            "boardposition" => boardposition
        }
        NxBoardItems::commit(item)
        item
    end

    # ----------------------------------------------------------------
    # Data

    # NxBoards::toString(item)
    def self.toString(item)
        loadDoneInHours = BankCore::getValue(item["uuid"]).to_f/3600 + item["hours"]
        loadLeftInhours = item["hours"] - loadDoneInHours
        timePassedInDays = (Time.new.to_i - item["lastResetTime"]).to_f/86400
        timeLeftInDays = 7 - timePassedInDays
        str1 = "(done #{("%5.2f" % loadDoneInHours).to_s.green} out of #{item["hours"]})"
        str2 = 
            if timeLeftInDays > 0 then
                "(#{timeLeftInDays.round(2)} days before reset)"
            else
                "(late by #{-timeLeftInDays.round(2)})"
            end
        str3 = "(cr: #{"%5.2f" % NxBoards::completionRatio(item)})"
        "(board) #{item["description"].ljust(8)} #{str1} #{str2} #{str3}"
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
        NxBoards::boardItemsOrdered(board["uuid"])
            .first(20)
            .each{|item| puts NxBoardItems::toString(item) }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
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
            .select{|packet| packet["cr"] < 1 }
            .sort{|p1, p2| p1["cr"] <=> p2["cr"] }
            .map {|packet| packet["board"] }
    end

    # NxBoards::bottomItems()
    def self.bottomItems()
        NxBoards::items()
            .map {|board|
                {
                    "board" => board,
                    "cr"    => NxBoards::completionRatio(board)
                }
            }
            .sort{|p1, p2| p1["cr"] <=> p2["cr"] }
            .map {|packet| packet["board"] }
    end

    # NxBoards::boardItems(boarduuid)
    def self.boardItems(boarduuid)
        NxBoardItems::items().select{|item| item["boarduuid"] == boarduuid }
    end

    # NxBoards::boardItemsOrdered(boarduuid)
    def self.boardItemsOrdered(boarduuid)
        NxBoards::boardItems(boarduuid)
            .sort{|i1, i2| i1["boardposition"] <=> i2["boardposition"] }
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
            if BankCore::getValue(item["uuid"]) >= 0 and (Time.new.to_i - item["lastResetTime"]) >= 86400*7 then
                puts "resetting time commitment board: #{item["description"]}"
                BankCore::put(item["uuid"], -engine["hours"]*3600)
                item["lastResetTime"] = Time.new.to_i
                NxBoards::commit(item)
            end
        }
    end

    # NxBoards::interactivelyOffersToAttachBoard(item)
    def self.interactivelyOffersToAttachBoard(item)
        return if item["mikuType"] == "NxBoard"
        return if item["mikuType"] == "NxBoardItem"
        return if Lookups::isValued("NonBoardItemToBoardMapping", item["uuid"])
        puts "attaching board for accounting"
        board = NxBoards::interactivelySelectOneOrNull()
        return if board.nil?
        Lookups::commit("NonBoardItemToBoardMapping", item["uuid"], board)
    end

    # NxBoards::toStringSuffix(item)
    def self.toStringSuffix(item)
        board = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
        return "" if board.nil?
        " (board: #{board["description"]})".green
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
                bx = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
                return false if bx.nil?
                return false if bx["uuid"] != boarduuid
                true
            }).call()
        }
        waves = Waves::items().select{|item|
            (lambda{
                bx = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
                return false if bx.nil?
                return false if bx["uuid"] != boarduuid
                true
            }).call()
        }
        items = NxBoards::boardItemsOrdered(board["uuid"])

        store.register(board, (tops+waves+items).empty?)
        spacecontrol.putsline "(#{store.prefixString()}) #{NxBoards::toString(board)}"
        NxOpens::itemsForBoard(boarduuid).each{|item|
            store.register(item, false)
            spacecontrol.putsline "(#{store.prefixString()}) (open) #{item["description"]}".yellow
        }

        lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }

        lockedItems
            .each{|item|
                store.register(item, false)
                spacecontrol.putsline (Listing::itemToListingLine(store, item))
            }

        tops.each{|item|
            store.register(item, true)
            spacecontrol.putsline (Listing::itemToListingLine(store, item))
        }

        waves.each{|item|
            store.register(item, true)
            spacecontrol.putsline (Listing::itemToListingLine(store, item))
        }

        items.take(6)
            .each{|item|
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
        spacecontrol.putsline "(#{store.prefixString()}) #{NxBoards::toString(board)}#{DoNotShowUntil::suffixString(board)}"
        NxOpens::itemsForBoard(boarduuid).each{|item|
            store.register(item, false)
            spacecontrol.putsline "#{padding}(#{store.prefixString()}) (open) #{item["description"]}".yellow
        }

        items = NxBoards::boardItemsOrdered(board["uuid"])

        lockedItems, items = items.partition{|item| Locks::isLocked(item["uuid"]) }

        lockedItems
            .each{|item|
                store.register(item, false)
                spacecontrol.putsline (padding + Listing::itemToListingLine(store, item))
            }

        NxTops::itemsInOrder().each{|item|
            bx = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
            next if bx.nil?
            next if bx["uuid"] != boarduuid
            store.register(item, false)
            spacecontrol.putsline (padding + Listing::itemToListingLine(store, item))
        }

        Waves::items().each{|item|
            bx = Lookups::getValueOrNull("NonBoardItemToBoardMapping", item["uuid"])
            next if bx.nil?
            next if bx["uuid"] != boarduuid
            store.register(item, false)
            spacecontrol.putsline (padding + Listing::itemToListingLine(store, item))
        }

        items.take(6)
            .each{|item|
                store.register(item, false)
                spacecontrol.putsline (padding + Listing::itemToListingLine(store, item))
            }
    end
end