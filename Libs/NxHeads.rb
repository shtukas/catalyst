# encoding: UTF-8

class NxHeads

    # NxHeads::items()
    def self.items()
        N3Objects::getMikuType("NxHead")
    end

    # NxHeads::bItemsOrdered(boarduuid or nil)
    def self.bItemsOrdered(boarduuid)
        NxHeads::items()
            .select{|item| item["boarding"]["boarduuid"] == boarduuid }
            .sort{|i1, i2| i1["boarding"]["position"] <=> i2["boarding"]["position"] }
    end

    # NxHeads::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxHeads::getItemOfNull(uuid)
    def self.getItemOfNull(uuid)
        N3Objects::getOrNull(uuid)
    end

    # NxHeads::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxHeads::interactivelyIssueNewBoardlessOrNull()
    def self.interactivelyIssueNewBoardlessOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = NxList::midposition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarding"    => {
                "boarduuid" => nil,
                "position"  => position
            }
        }
        NxHeads::commit(item)
        item
    end

    # NxHeads::interactivelyIssueNewBoardedOrNull()
    def self.interactivelyIssueNewBoardedOrNull()
        board = NxBoards::interactivelySelectOne()
        position = NxBoards::interactivelyDecideNewBoardPosition(board)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarding"    => {
                "boarduuid" => board["uuid"],
                "position"  => position
            }
        }
        NxHeads::commit(item)
        item
    end

    # NxHeads::netflix(title)
    def self.netflix(title)
        uuid  = SecureRandom.uuid
        position = NxList::midposition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => "Watch '#{title}' on Netflix",
            "field11"     => nil,
            "boarding"    => {
                "boarduuid" => nil,
                "position"  => position
            }
        }
        NxHeads::commit(item)
        item
    end

    # NxHeads::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        coredataref = "url:#{N1Data::putBlob(url)}"
        position = NxList::midposition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarding"    => {
                "boarduuid" => nil,
                "position"  => position
            }
        }
        NxTails::commit(item)
        item
    end

    # NxHeads::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nhash = AionCore::commitLocationReturnHash(N1DataElizabeth.new(), location)
        coredataref = "aion-point:#{nhash}"
        position = NxList::midposition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarding"    => {
                "boarduuid" => nil,
                "position"  => position
            }
        }
        NxTails::commit(item)
        item
    end

    # NxHeads::priority()
    def self.priority()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = NxHeads::startPosition() - 1
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxHead",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarding"    => {
                "boarduuid" => nil,
                "position"  => position
            }
        }
        NxHeads::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxHeads::isBoarded(item)
    def self.isBoarded(item)
        !item["boarding"]["boarduuid"].nil?
    end

    # NxHeads::toString(item)
    def self.toString(item)
        if NxHeads::isBoarded(item) then
            "(bi) (pos: #{item["boarding"]["position"].round(3)}) #{item["description"]}"
        else
            rt = BankUtils::recoveredAverageHoursPerDay(item["uuid"])
            "(list) (#{"%5.2f" % rt}) #{item["description"]}"
        end
    end

    # NxHeads::startZone()
    def self.startZone()
        NxHeads::bItemsOrdered(nil).map{|item| item["boarding"]["position"] }.sort.take(3).inject(0, :+).to_f/3
    end

    # NxHeads::startPosition()
    def self.startPosition()
        positions = NxHeads::bItemsOrdered(nil).map{|item| item["boarding"]["position"] }
        return NxTails::frontPosition() - 1 if positions.empty?
        positions.min
    end

    # NxHeads::endPosition()
    def self.endPosition()
        positions = NxHeads::bItemsOrdered(nil).map{|item| item["boarding"]["position"] }
        return NxTails::frontPosition() - 1 if positions.empty?
        positions.max
    end

    # NxHeads::listingItems(boarduuid or nil)
    def self.listingItems(boarduuid)
        if boarduuid.nil? then

            items = NxHeads::bItemsOrdered(nil)
                .sort{|i1, i2| i1["boarding"]["position"] <=> i2["boarding"]["position"] }
                .take(3)
                .map {|item|
                    {
                        "item" => item,
                        "rt"   => BankUtils::recoveredAverageHoursPerDay(item["uuid"])
                    }
                }
                .select{|packet| packet["rt"] < 1 }
                .sort{|p1, p2| p1["rt"] <=> p2["rt"] }
                .map {|packet| packet["item"] }

            return items if items.size > 0

            # If we reach this point it means that all first three items have a rt >= 1,
            # let's try the next three and we stop at them.

            NxHeads::bItemsOrdered(nil)
                .sort{|i1, i2| i1["boarding"]["position"] <=> i2["boarding"]["position"] }
                .drop(3)
                .take(3)
                .map {|item|
                    {
                        "item" => item,
                        "rt"   => BankUtils::recoveredAverageHoursPerDay(item["uuid"])
                    }
                }
                .select{|packet| packet["rt"] < 1 }
                .sort{|p1, p2| p1["rt"] <=> p2["rt"] }
                .map {|packet| packet["item"] }

        else

            NxHeads::bItemsOrdered(boarduuid)
                .sort{|i1, i2| i1["boarding"]["position"] <=> i2["boarding"]["position"] }

        end
    end

    # NxHeads::listingRunningItems()
    def self.listingRunningItems()
        NxHeads::items().select{|item| NxBalls::itemIsActive(item) }
    end

    # --------------------------------------------------
    # Operations

    # NxHeads::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end

    # NxHeads::dataManagement()
    def self.dataManagement()
        NxHeads::items()
            .select{|item| !NxHeads::isBoarded(item) }
            .select{|item| BankCore::getValue(item["uuid"]) > (3600 * 3.14159) }
            .each{|item|
                puts "> NxHead item '#{item["description"]}' has #{(BankCore::getValue(item["uuid"]).to_f/3600).round(2)} hours in the bank"
                puts "> recasting as NxProject"
                LucilleCore::pressEnterToContinue()
                item["mikuType"] = "NxProject"
                item["active"] = false
                N3Objects::commit(item)
            }
    end
end
