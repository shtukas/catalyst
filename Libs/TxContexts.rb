
class TxContexts

    # TxContexts::items()
    def self.items()
        N3Objects::getMikuType("TxContext")
    end

    # TxContexts::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # TxContexts::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # TxContexts::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "TxContext",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "boarduuid"   => NxBoards::interactivelySelectOne()["uuid"]
        }
        puts JSON.pretty_generate(item)
        TxContexts::commit(item)
        item
    end

    # TxContexts::toString(item)
    def self.toString(item)
        "(context) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end
end