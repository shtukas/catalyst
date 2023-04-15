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

    # NxTasks::interactivelyDecidePriority()
    def self.interactivelyDecidePriority()
        priority = LucilleCore::askQuestionAnswerAsString("priority (empty for default): ")
        if priority == "" then
            nil
        else
            priority.to_i
        end
    end

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

    # NxTasks::interactivelyDecidePosition1()
    def self.interactivelyDecidePosition1()
        actions = ["within top", "that position"]
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
        if action == "within top" then
            return NxTasks::interactivelyDecideTopPosition()
        end
        if action == "that position" then
            return NxTasks::thatPosition()
        end
        NxTasks::interactivelyDecidePosition1()
    end

    # NxTasks::interactivelyDecidePosition2(board)
    def self.interactivelyDecidePosition2(board)
        if board then
            NxBoards::interactivelyDecideNewBoardPosition(board)
        else
            NxTasks::interactivelyDecidePosition1()
        end
    end

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid        = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        board       = NxBoards::interactivelySelectOneOrNull()
        boarduuid   = board ? board["uuid"] : nil
        position    = NxTasks::interactivelyDecidePosition2(board)
        engine      = TxEngines::interactivelyMakeEngine()
        priority    = NxTasks::interactivelyDecidePriority()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTask",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position,
            "boarduuid"   => boarduuid,
            "priority"    => priority,
            "engine"      => engine
        }
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
        }
        NxTasks::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTasks::bItemsOrdered(board)
    def self.bItemsOrdered(board)
        NxTasks::items()
            .select{|item| BoardsAndItems::belongsToThisBoard2ForListingManagement(item, board) }
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
    end

    # NxTasks::isBoarded(item)
    def self.isBoarded(item)
        !item["boarduuid"].nil?
    end

    # NxTasks::toString(item)
    def self.toString(item)
        isPriority = item["priority"] and item["priority"] > 1
        position1 = 
            if isPriority then
                ""
            else
                " (@ #{item["position"].round(3)})"
            end
        performance1 = 
            if isPriority then
                # Here we are only interested in the RT
                " (performance: #{"%4.2f" % BankUtils::recoveredAverageHoursPerDay(item["uuid"]).round(2)})"
            else
                ""
            end
        performance2 = 
            if isPriority then
                ""
            else
                " #{TxEngines::toString(item["engine"])}"
            end
        priority1 = (item["priority"] and item["priority"] > 1) ? " (priority: #{item["priority"]})" : "" 
        "(task)#{position1}#{performance1} #{item["description"]}#{performance2}#{priority1}"
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

    # --------------------------------------------------
    # Listing Items

    # NxTasks::listingItemsPriority()
    def self.listingItemsPriority()
        items = NxTasks::items()
        topPriority = items.map{|item| item["priority"] || 1 }.max
        return [] if topPriority == 1
        NxTasks::items()
            .select{|item| (item["priority"] || 1) == topPriority }
            .sort{|i1, i2| BankUtils::recoveredAverageHoursPerDay(i1["uuid"]) <=> BankUtils::recoveredAverageHoursPerDay(i2["uuid"]) }
    end

    # NxTasks::listingItemsNil(count)
    def self.listingItemsNil(count)
        NxTasks::bItemsOrdered(nil)
            .select{|item| item["boarduuid"].nil? }
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

    # NxTasks::listingItems(count)
    def self.listingItems(count)
        items0 = NxTasks::listingItemsNil(3).select{|item| NxTasks::completionRatio(item) < 1 }
        items1 = NxBoards::boardsOrdered()
                    .select{|board| DoNotShowUntil::isVisible(board) }
                    .select{|board| TxEngines::completionRatio(board["engine"]) < 1 }
                    .map{|board| NxTasks::bItemsOrdered(board)}
                    .flatten
        items2 = NxTasks::listingItemsNil(count)
        (items0+items1+items2).map{|item|
            TxEngines::updateItemOrNothing(item)
        }
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
            return if input == "exit"

            Listing::listingCommandInterpreter(input, store, nil)
        }
    end

end
