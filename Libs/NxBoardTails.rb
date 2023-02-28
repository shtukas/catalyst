
class NxBoardTails

    # NxBoardTails::items()
    def self.items()
        N3Objects::getMikuType("NxBoardTail")
    end

    # NxBoardTails::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxBoardTails::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxBoardTails::interactivelyIssueNullOrNull()
    def self.interactivelyIssueNullOrNull()
        board = NxBoards::interactivelySelectOneOrNull()
        return nil if board.nil?
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxBoardTail",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"   => board["uuid"]
        }
        NxBoardTails::commit(item)
        item
    end

    # NxBoardTails::toString(item)
    def self.toString(item)
        "(btail) #{item["description"]}"
    end

    # NxBoardTails::listingItems()
    def self.listingItems()
        NxBoardTails::items()
    end

    # NxBoardTails::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end