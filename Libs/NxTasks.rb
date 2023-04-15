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

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        board = NxBoards::interactivelySelectOneOrNull()
        priority = LucilleCore::askQuestionAnswerAsString("priority (empty for default): ")
        if priority == "" then
            priority = nil
        else
            priority = priority.to_i
        end
        if board then
            position = NxBoards::interactivelyDecideNewBoardPosition(board)
            item = {
                "uuid"        => uuid,
                "mikuType"    => "NxTask",
                "unixtime"    => Time.new.to_i,
                "datetime"    => Time.new.utc.iso8601,
                "description" => description,
                "field11"     => coredataref,
                "position"    => position,
                "boarduuid"   => board["uuid"],
                "priority"    => priority
            }
        else
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
                "priority"    => priority
            }
        end
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
        "(task) (@ #{item["position"].round(3)}) #{item["description"]} #{TxEngines::toString(item["engine"])}#{(item["priority"] and item["priority"] > 1) ? " (priority: #{item["priority"]})" : "" }"
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

    # --------------------------------------------------
    # Listing Items

    # NxTasks::listingItemsPriority()
    def self.listingItemsPriority()
        items = NxTasks::items()
        topPriority = items.map{|item| item["priority"] || 1 }.max
        if topPriority > 1 then
            XCache::set("adc9c640-93b5-415e-a9e5-f59b3ea793d5", "true")
        else
            XCache::set("adc9c640-93b5-415e-a9e5-f59b3ea793d5", "false")
        end
        return [] if topPriority == 1
        NxTasks::items()
            .select{|item| (item["priority"] || 1) == topPriority }
            .sort{|i1, i2| BankCore::getValueAtDate(i1["uuid"], CommonUtils::today()) <=> BankCore::getValueAtDate(i2["uuid"], CommonUtils::today()) }
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
        return [] if XCache::getOrNull("adc9c640-93b5-415e-a9e5-f59b3ea793d5") == "true"

        items1 = NxBoards::boardsOrdered()
                    .select{|board| DoNotShowUntil::isVisible(board) }
                    .select{|board| TxEngines::completionRatio(board["engine"]) < 1 }
                    .map{|board| NxTasks::bItemsOrdered(board)}
                    .flatten
        items2 = NxTasks::listingItemsNil(count)
        (items1+items2).map{|item|
            TxEngines::updateItemOrNothing(item)
        }
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end

    # NxTasks::program(item)
    def self.program(item)
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

end
