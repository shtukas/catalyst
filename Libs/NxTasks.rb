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

    # NxTasks::priority()
    def self.priority()
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
        if NxTasks::isBoarded(item) then
            "(task) (pos: #{item["position"].round(3)}) #{item["description"]}"
        else
            rt = BankUtils::recoveredAverageHoursPerDay(item["uuid"])
            "(task) (#{"%5.2f" % rt}) #{item["description"]}#{DoNotShowUntil::suffixString(item)}"
        end
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

    # NxTasks::listingItemsNil()
    def self.listingItemsNil()
        getItemOrNull = lambda {
            item = nil
            uuid = XCache::getOrNull("b338aac9-4765-4d7c-afd6-e34ff6bfcd56")
            if uuid then
                item = N3Objects::getOrNull(uuid)
                if item then
                    if BankUtils::recoveredAverageHoursPerDay(item["uuid"]) < 1 then
                        return item
                    end
                end
            end
            item = NxTasks::bItemsOrdered(nil)
                    .select{|item| item["boarduuid"].nil? }
                    .sort{|i1, i2| i1["position"] <=> i2["position"] }
                    .reduce(nil){|selected, i|
                        if selected then
                            selected
                        else
                            if DoNotShowUntil::isVisible(i) then
                                if BankUtils::recoveredAverageHoursPerDay(i["uuid"]) < 1 then
                                    i
                                else
                                    nil
                                end
                            else
                                nil
                            end
                        end
                    }
            XCache::set("b338aac9-4765-4d7c-afd6-e34ff6bfcd56", item["uuid"])
            item
        }

        item = getItemOrNull.call()

        return [] if (BankUtils::recoveredAverageHoursPerDay("34c37c3e-d9b8-41c7-a122-ddd1cb85ddbc") > 3 and !NxBalls::itemIsRunning(item))

        [item]
    end

    # NxTasks::listingItems()
    def self.listingItems()
        items1 = NxBoards::boardsOrdered()
                    .select{|board| DoNotShowUntil::isVisible(board) }
                    .select{|board| NxBoards::completionRatio(board) < 1 }
                    .map{|board| NxTasks::bItemsOrdered(board).first(6) }
                    .flatten
        items2 = NxTasks::listingItemsNil()
        items1+items2
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
