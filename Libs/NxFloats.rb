
class NxFloats

    # NxFloats::items()
    def self.items()
        N3Objects::getMikuType("NxFloat")
    end

    # NxFloats::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxFloats::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxFloats::interactivelyIssueNullOrNull()
    def self.interactivelyIssueNullOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxFloat",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description
        }
        puts JSON.pretty_generate(item)
        NxFloats::commit(item)
        item
    end

    # NxFloats::toString(item)
    def self.toString(item)
        "(float) #{item["description"]}"
    end

    # NxFloats::listingItems(boarduuid)
    def self.listingItems(boarduuid)
        if boarduuid then
            NxFloats::items()
                .select{|item|
                    (lambda{|item|
                        board = BoardsAndItems::getBoardOrNull(item)
                        return false if board.nil?
                        return false if (board["uuid"] != boarduuid)
                        true
                    }).call(item)
                }
        else
            NxFloats::items()
                .select{|item| BoardsAndItems::getBoardOrNull(item).nil? }
        end

    end
end