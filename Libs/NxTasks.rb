# encoding: UTF-8

class NxTasks

    # NxTasks::items()
    def self.items()
        N3Objects::getMikuType("NxTask")
    end

    # NxTasks::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxTasks::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        N3Objects::getOrNull(uuid)
    end

    # NxTasks::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyDecideTopPosition()
    def self.interactivelyDecideTopPosition()
        items = NxTasks::items()
                    .select{|item| item["boarduuid"].nil? }
                    .sort_by{|item| item["position"] }
                    .first(30)
        return 1 if items.empty?
        items.each{|item| puts NxTasks::toString(item) }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        if position == "" then
            return items.map{|item| item["position"] }.max + 1
        end
        return position.to_f
    end

    # NxTasks::interactivelyDecideBoardlessPosition()
    def self.interactivelyDecideBoardlessPosition()
        actions = ["within top", "that position"]
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
        if action == "within top" then
            return NxTasks::interactivelyDecideTopPosition()
        end
        if action == "that position" then
            return NxTasks::thatPosition()
        end
        NxTasks::interactivelyDecideBoardlessPosition()
    end

    # NxTasks::interactivelyDecidePosition2(board)
    def self.interactivelyDecidePosition2(board)
        if board then
            NxBoards::interactivelyDecideNewBoardPosition(board)
        else
            NxTasks::interactivelyDecideBoardlessPosition()
        end
    end

    # NxTasks::setHyperspatialCoordinates(item)
    def self.setHyperspatialCoordinates(item)
        board     = NxBoards::interactivelySelectOneOrNull()
        boarduuid = board ? board["uuid"] : nil
        position  = NxTasks::interactivelyDecidePosition2(board)
        engine    = TxEngines::interactivelyMakeEngine()

        item["boarduuid"] = boarduuid
        item["position"]  = position
        item["engine"]    = engine

        item
    end

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        item = {}
        item["uuid"] = uuid
        item["mikuType"] = "NxTask"
        item["unixtime"] = Time.new.to_i
        item["datetime"] = Time.new.utc.iso8601
        item["description"] = description
        item["field11"] = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)

        puts "1"
        puts JSON.pretty_generate(item)

        item = NxTasks::setHyperspatialCoordinates(item)

        NxTasks::commit(item)
        item
    end

    # NxTasks::netflix(title)
    def self.netflix(title)
        uuid  = SecureRandom.uuid
        position = NxTasks::thatPosition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTask",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => "Watch '#{title}' on Netflix",
            "field11"     => nil,
            "position"    => position,
            "boarduuid"   => nil,
            "engine"      => TxEngines::defaultEngine(nil)
        }
        NxTasks::commit(item)
        item
    end

    # NxTasks::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        coredataref = "url:#{N1Data::putBlob(url)}"
        position = NxTasks::newMinus1Position()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTask",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position,
            "engine"      => TxEngines::defaultEngine(nil)
        }
        N3Objects::commit(item)
        item
    end

    # NxTasks::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nhash = AionCore::commitLocationReturnHash(N1DataElizabeth.new(), location)
        coredataref = "aion-point:#{nhash}"
        position = NxTasks::thatPosition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTask",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position,
            "boarduuid"   => nil,
            "engine"      => TxEngines::defaultEngine(nil)
        }
        N3Objects::commit(item)
        item
    end

    # NxTasks::makeFirstTask()
    def self.makeFirstTask()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = NxTasks::startPosition() - 1
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTask",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position,
            "boarduuid"   => nil,
            "engine"      => TxEngines::defaultEngine(nil)
        }
        NxTasks::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTasks::boardItemsOrdered(board)
    def self.boardItemsOrdered(board)
        NxTasks::items()
            .select{|item| item["boarduuid"] == board["uuid"] }
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
    end

    # NxTasks::boardlessItemsOrdered()
    def self.boardlessItemsOrdered()
        NxTasks::items()
            .select{|item| item["boarduuid"].nil? }
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
    end

    # NxTasks::toString(item)
    def self.toString(item)
        if item["engine"]["type"] == "priority" then
            return "(#{"priority".green}, performance: #{BankUtils::recoveredAverageHoursPerDay(item["uuid"]).round(2)}) #{item["description"]}"
        end

        "(task) (@ #{item["position"].round(3)}) #{item["description"]} #{TxEngines::toString(item["engine"])}"
    end

    # NxTasks::startPosition()
    def self.startPosition()
        positions = NxTasks::items().map{|item| item["position"] }
        return 1 if positions.empty?
        positions.min
    end

    # NxTasks::endPosition()
    def self.endPosition()
        positions = NxTasks::items().map{|item| item["position"] }
        return 1 if positions.empty?
        positions.max
    end

    # NxTasks::positionsToNewPosition(positions)
    def self.positionsToNewPosition(positions)
        if positions.empty? then
            return 1
        end

        if positions.size < 3 then
            return positions.max + 0.5 + 0.5*rand
        end

        # So we have at least 3 elements.
        differences = positions.zip(positions.drop(1)).select{|pair| pair[1] }.map{|x1, x2| x2 - x1}

        # We have at least two differences
        average = differences.sum.to_f/differences.size
        a1 = positions.zip(differences).select{|pair| pair[1] }
        position, difference = a1.select{|pair| pair[1] >= average }.first

        position + rand*difference
    end

    # NxTasks::newMinus1Position()
    def self.newMinus1Position()
        positions = NxTasks::items().map{|item| item["position"] }
        return 1 if positions.empty?
        positions.min - 1
    end

    # NxTasks::thatPosition()
    def self.thatPosition()
        positions = NxTasks::items().map{|item| item["position"] }.take(100)
        NxTasks::positionsToNewPosition(positions)
    end

    # NxTasks::completionRatio(item)
    def self.completionRatio(item)
        TxEngines::completionRatio(item["engine"]) 
    end

    # NxTasks::performance()
    def self.performance()
        (-6..0)
            .map{|i| BankCore::getValueAtDate("34c37c3e-d9b8-41c7-a122-ddd1cb85ddbc", CommonUtils::nDaysInTheFuture(i))}
            .inject(0, :+)
            .to_f/3600
    end

    # --------------------------------------------------
    # Listing Items

    # NxTasks::listingItemsBoardlessHead(count)
    def self.listingItemsBoardlessHead(count)
        NxTasks::boardlessItemsOrdered()
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
            .reduce([]){|selected, i|
                if selected.size >= count then
                    selected
                else
                    if DoNotShowUntil::isVisible(i) then
                        selected + [i]
                    else
                        selected
                    end
                end
            }
    end

    # NxTasks::listingItemsHeadForBoard(board, count)
    def self.listingItemsHeadForBoard(board, count)
        NxTasks::boardItemsOrdered(board)
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
            .reduce([]){|selected, i|
                if selected.size >= count then
                    selected
                else
                    if DoNotShowUntil::isVisible(i) then
                        selected + [i]
                    else
                        selected
                    end
                end
            }
    end

    # NxTasks::listingItemsTail(count)
    def self.listingItemsTail(count)
        NxTasks::boardlessItemsOrdered()
            .reverse
            .reduce([]){|selected, i|
                if selected.size >= count then
                    selected
                else
                    if DoNotShowUntil::isVisible(i) then
                        selected + [i]
                    else
                        selected
                    end
                end
            }
    end

    # NxTasks::club()
    def self.club()
        items1 = NxBoards::boardsOrdered()
                    .select{|board| DoNotShowUntil::isVisible(board) }
                    .select{|board| TxEngines::completionRatio(board["engine"]) < 1 }
                    .sort_by{|board| TxEngines::completionRatio(board["engine"]) }
                    .map{|board| NxTasks::listingItemsHeadForBoard(board, 6) }
                    .flatten
        items2 = NxTasks::listingItemsBoardlessHead(3)
        items3 = NxTasks::listingItemsTail(3)
        (items1+items2+items3).map{|item|
            TxEngines::engineMaintenanceOrNothing(item)
        }
    end

    # NxTasks::listingItems()
    def self.listingItems()
        priorityItems = NxTasks::items()
                            .select{|item| item["engine"]["type"] == "priority" }
                            .sort_by{|item| BankUtils::recoveredAverageHoursPerDay(item["uuid"]) }

        priorityItems + NxTasks::club()
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end

    # NxTasks::program1(item)
    def self.program1(item)
        loop {
            puts NxTasks::toString(item)
            actions = ["set priority", "re-engine"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            break if action.nil?
            if action == "set priority" then
                item["priority"] = LucilleCore::askQuestionAnswerAsString("priority: ").to_f
                N3Objects::commit(item)
            end
            if action == "re-engine" then
                item["engine"] = TxEngines::interactivelyMakeEngineOrNull(item["engine"]["uuid"])
                N3Objects::commit(item)
            end
        }
    end

    # NxTasks::program2()
    def self.program2()
        loop {
            store = ItemStore.new()

            items = NxTasks::items()
                    .select{|item| item["boarduuid"].nil? }
                    .sort_by{|item| item["position"] }
                    .first(50)

            Listing::program1(store, items)

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end

end
