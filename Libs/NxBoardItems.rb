# encoding: UTF-8

class NxBoardItems

    # NxBoardItems::items()
    def self.items()
        N1DataIO::getMikuType("NxBoardItem")
    end

    # NxBoardItems::commit(item)
    def self.commit(item)
        N1DataIO::commitObject(item)
    end

    # NxBoardItems::destroy(uuid)
    def self.destroy(uuid)
        N1DataIO::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxBoardItems::interactivelyIssueNewOrNull(board or null)
    def self.interactivelyIssueNewOrNull(board)
        board = board || NxBoards::interactivelySelectOne()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        boardposition = NxBoards::interactivelyDecideNewBoardPosition(board)
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxBoardItem",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "field11"       => coredataref,
            "boarduuid"     => board["uuid"],
            "boardposition" => boardposition
        }
        NxBoardItems::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxBoardItems::toString(item)
    def self.toString(item)
        "(pos: #{"%8.3f" % item["boardposition"]}) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # --------------------------------------------------
    # Operations

    # NxBoardItems::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
