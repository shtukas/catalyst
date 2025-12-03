
class NxNxTodays

    # NxNxTodays::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-uuid-1141", UxPayloads::interactivelyIssueNewGetReferenceOrNull())
        Items::setAttribute(uuid, "mikuType", "NxNxToday")
        item = Items::objectOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxNxTodays::icon()
    def self.icon()
        "🥐"
    end

    # NxNxTodays::toString(item)
    def self.toString(item)
        "#{NxNxTodays::icon()} #{item["description"]}"
    end

    # NxNxTodays::listingItems()
    def self.listingItems()
        Items::mikuType("NxNxToday")
    end
end
