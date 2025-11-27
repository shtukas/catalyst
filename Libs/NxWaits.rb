
class NxWaits

    # NxWaits::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-uuid-1141", UxPayloads::interactivelyIssueNewGetReferenceOrNull())
        Items::setAttribute(uuid, "mikuType", "NxWait")
        item = Items::objectOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxWaits::icon()
    def self.icon()
        "🪔"
    end

    # NxWaits::toString(item)
    def self.toString(item)
        "#{NxWaits::icon()} #{item["description"]}"
    end

    # NxWaits::listingItems()
    def self.listingItems()
        Items::mikuType("NxWait")
    end

    # NxWaits::listingPosition(item)
    def self.listingPosition(item)
        0.500
    end
end
