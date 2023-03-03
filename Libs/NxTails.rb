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
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTail",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"   => board ? board["uuid"] : nil
        }
        NxTails::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTails::bItems(boarduuidOpt)
    def self.bItems(boarduuidOpt)
        NxTails::items()
            .select{|item| item["boarduuid"] == boarduuidOpt }
    end

    # NxTails::toString(item)
    def self.toString(item)
        "(tail) #{item["description"]}"
    end

    # NxTails::getFrontElementOrNull(boarduuidOpt)
    def self.getFrontElementOrNull(boarduuidOpt)
        NxTails::bItems(boarduuidOpt)
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"]}
            .first
    end

    # NxTails::getEndElementOrNull(boarduuidOpt)
    def self.getEndElementOrNull(boarduuidOpt)
        NxTails::bItems(boarduuidOpt)
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"]}
            .last
    end

    # NxTails::listingItems(boarduuidOpt)
    def self.listingItems(boarduuidOpt)
        # We only call this function while displaying a board, not while displaying the main listing
        NxTails::bItems(boarduuidOpt)
    end

    # --------------------------------------------------
    # Operations

    # NxTails::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
