
class AbsolutelyTodays

    # AbsolutelyTodays::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-uuid-1141", UxPayloads::interactivelyIssueNewGetReferenceOrNull())
        Items::setAttribute(uuid, "mikuType", "AbsolutelyToday")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # AbsolutelyTodays::icon()
    def self.icon()
        "🥐"
    end

    # AbsolutelyTodays::toString(item)
    def self.toString(item)
        "#{AbsolutelyTodays::icon()} #{item["description"]}"
    end

    # AbsolutelyTodays::listingItems()
    def self.listingItems()
        Items::mikuType("AbsolutelyToday")
    end
end
