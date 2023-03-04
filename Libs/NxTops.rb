
class NxTops

    # NxTops::items()
    def self.items()
        N3Objects::getMikuType("NxTop")
    end

    # NxTops::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxTops::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxTops::interactivelyDecideOrdinalOrNull(board)
    def self.interactivelyDecideOrdinalOrNull(board)
        existingItems = NxTops::bItems(board)
        return 1 if existingItems.empty?
        existingItems.each{|item|
            puts NxTops::toString(item)
        }
        LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
    end

    # NxTops::interactivelyIssueNullOrNull(useCoreData: true)
    def self.interactivelyIssueNullOrNull(useCoreData: true)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        board = NxBoards::interactivelySelectOneOrNull()
        ordinal = NxTops::interactivelyDecideOrdinalOrNull(board)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTop",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ordinal"     => ordinal
        }
        puts JSON.pretty_generate(item)
        NxTops::commit(item)
        BoardsAndItems::attachToItem(item, board)
        item
    end

    # NxTops::toString(item)
    def self.toString(item)
        "(top) (#{"%5.2f" % item["ordinal"]}) #{item["description"]}"
    end

    # NxTops::itemsInOrder()
    def self.itemsInOrder()
        NxTops::items().sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
    end

    # NxTops::bItems(board or nil)
    def self.bItems(board)
        NxTops::itemsInOrder()
            .select{|item| BoardsAndItems::belongsToThisBoard(item, board) }
    end

    # NxTops::listingItems(board or nil)
    def self.listingItems(board)
        NxTops::bItems(board)
    end
end