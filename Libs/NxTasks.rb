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
            position = NxTasks::nextPosition()
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
        position = NxTasks::nextPosition()
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
        position = NxTasks::nextPosition()
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
        position = NxTasks::nextPosition()
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
            .select{|item| BoardsAndItems::belongsToThisBoard(item, board) }
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

    # NxTasks::nextPosition()
    def self.nextPosition()
        positions = NxTasks::items().map{|item| item["position"] }.take(100)
        NxTasks::positionsToNewPosition(positions)
    end

    # NxTasks::listingItems(board)
    def self.listingItems(board)
        if board then
            NxTasks::bItemsOrdered(board)
        else
            NxTasks::bItemsOrdered(nil)
                .first(10)
                .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
                .first(3)
                .select{|item| BankUtils::recoveredAverageHoursPerDay(item["uuid"]) < 1 }
                .sort_by{|item| BankUtils::recoveredAverageHoursPerDay(item["uuid"]) }
        end
    end

    # NxTasks::listingRunningItems()
    def self.listingRunningItems()
        NxTasks::items().select{|item| NxBalls::itemIsActive(item) }
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
