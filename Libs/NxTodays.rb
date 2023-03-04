
class NxTodays

    # NxTodays::items()
    def self.items()
        N3Objects::getMikuType("NxToday")
    end

    # NxTodays::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxTodays::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxTodays::interactivelyIssueNullOrNull(useCoreData: true)
    def self.interactivelyIssueNullOrNull(useCoreData: true)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = useCoreData ? CoreData::interactivelyMakeNewReferenceStringOrNull(uuid) : nil
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxToday",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref
        }
        puts JSON.pretty_generate(item)
        NxTodays::commit(item)
        BoardsAndItems::attachToItem(item, board)
        item
    end

    # NxTodays::toString(item)
    def self.toString(item)
        "(today) (#{"%5.2f" % item["ordinal"]}) #{item["description"]}"
    end

    # NxTodays::listingItems()
    def self.listingItems()
        NxTodays::items()
    end
end