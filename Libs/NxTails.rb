# encoding: UTF-8

class NxTails

    # NxTails::items()
    def self.items()
        N3Objects::getMikuType("NxTail")
    end

    # NxTails::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxTails::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        N3Objects::getOrNull(uuid)
    end

    # NxTails::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTails::interactivelyIssueNewOrNull(useCoreData: true)
    def self.interactivelyIssueNewOrNull(useCoreData: true)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = useCoreData ? CoreData::interactivelyMakeNewReferenceStringOrNull(uuid) : nil
        board = NxBoards::interactivelySelectOneOrNull()
        if board then
            position = NxBoards::interactivelyDecideNewBoardPosition(board)
            item = {
                "uuid"        => uuid,
                "mikuType"    => "NxTail",
                "unixtime"    => Time.new.to_i,
                "datetime"    => Time.new.utc.iso8601,
                "description" => description,
                "field11"     => coredataref,
                "position"    => position,
                "boarduuid"   => board["uuid"],
            }
        else
            position = NxTails::endPositionNext()
            item = {
                "uuid"        => uuid,
                "mikuType"    => "NxTail",
                "unixtime"    => Time.new.to_i,
                "datetime"    => Time.new.utc.iso8601,
                "description" => description,
                "field11"     => coredataref,
                "position"    => position,
                "boarduuid"   => nil,
            }
        end
        NxTails::commit(item)
        item
    end

    # NxTails::netflix(title)
    def self.netflix(title)
        uuid  = SecureRandom.uuid
        position = NxTails::endPositionNext()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTail",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => "Watch '#{title}' on Netflix",
            "field11"     => nil,
            "position"    => position,
            "boarduuid"   => nil,
        }
        NxTails::commit(item)
        item
    end

    # NxTails::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        coredataref = "url:#{N1Data::putBlob(url)}"
        position = NxTails::endPositionNext()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTail",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position,
            "boarduuid"   => board["uuid"],
        }
        N3Objects::commit(item)
        item
    end

    # NxTails::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nhash = AionCore::commitLocationReturnHash(N1DataElizabeth.new(), location)
        coredataref = "aion-point:#{nhash}"
        position = NxTails::endPositionNext()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTail",
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

    # NxTails::priority()
    def self.priority()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = NxTails::startPosition() - 1
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTail",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position,
            "boarduuid"   => nil,
        }
        NxTails::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTails::bItemsOrdered(boarduuid or nil)
    def self.bItemsOrdered(boarduuid)
        NxTails::items()
            .select{|item| item["boarduuid"] == boarduuid }
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
    end

    # NxTails::isBoarded(item)
    def self.isBoarded(item)
        !item["boarduuid"].nil?
    end

    # NxTails::toString(item)
    def self.toString(item)
        if NxTails::isBoarded(item) then
            "(tail) (pos: #{item["position"].round(3)}) #{item["description"]}"
        else
            rt = BankUtils::recoveredAverageHoursPerDay(item["uuid"])
            "(tail) (#{"%5.2f" % rt}) #{item["description"]}#{DoNotShowUntil::suffixString(item)}"
        end
    end

    # NxTails::startPosition()
    def self.startPosition()
        positions = NxTails::items().map{|item| item["position"] }
        return 1 if positions.empty?
        positions.min
    end

    # NxTails::endPosition()
    def self.endPosition()
        positions = NxTails::items().map{|item| item["position"] }
        return 1 if positions.empty?
        positions.max
    end

    # NxTails::endPositionNext()
    def self.endPositionNext()
        NxTails::endPosition() + 0.5 + 0.5*rand
    end

    # NxTails::listingItems(boarduuid or nil)
    def self.listingItems(boarduuid)
        NxTails::bItemsOrdered(boarduuid).first(10)
    end

    # NxTails::listingRunningItems()
    def self.listingRunningItems()
        NxTails::items().select{|item| NxBalls::itemIsActive(item) }
    end

    # --------------------------------------------------
    # Operations

    # NxTails::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
