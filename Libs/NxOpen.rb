
class NxOpens

    # NxOpens::items()
    def self.items()
        N1DataIO::getMikuType("NxOpen")
    end

    # NxOpens::commit(item)
    def self.commit(item)
        N1DataIO::commitObject(item)
    end

    # NxOpens::destroy(uuid)
    def self.destroy(uuid)
        N1DataIO::destroy(uuid)
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

    # NxOpens::itemsBoardFree()
    def self.itemsBoardFree()
        NxOpens::items()
            .select{|item| !NonBoardItemToBoardMapping::hasValue(item)}
    end

    # NxOpens::itemsForBoard(boarduuid)
    def self.itemsForBoard(boarduuid)
        NxOpens::items()
            .select{|item|
                (lambda{|item|
                    board = NonBoardItemToBoardMapping::getBoardOrNull(item)
                    return false if board.nil?
                    return false if board["uuid"] != boarduuid
                    true
                }).call(item)
            }
    end
end