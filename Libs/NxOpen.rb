
class NxOpens

    # NxOpens::items()
    def self.items()
        N3Objects::getMikuType("NxOpen")
    end

    # NxOpens::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxOpens::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxOpens::interactivelyIssueNullOrNull()
    def self.interactivelyIssueNullOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOpen",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description
        }
        puts JSON.pretty_generate(item)
        NxOpens::commit(item)
        item
    end

    # NxOpens::toString(item)
    def self.toString(item)
        "(open) #{item["description"]}"
    end

    # NxOpens::listingItems(boarduuid)
    def self.listingItems(boarduuid)
        if boarduuid then
            NxOpens::items()
                .select{|item|
                    (lambda{|item|
                        board = NonBoardItemToBoardMapping::getBoardOrNull(item)
                        return false if board.nil?
                        return false if (board["uuid"] != boarduuid)
                        true
                    }).call(item)
                }
        else
            NxOpens::items()
                .select{|item| NonBoardItemToBoardMapping::getBoardOrNull(item).nil? }
        end

    end
end