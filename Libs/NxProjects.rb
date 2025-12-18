
class NxProjects

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-uuid-1141", UxPayloads::interactivelyIssueNewGetReferenceOrNull())
        Items::setAttribute(uuid, "mikuType", "NxProject")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxProjects::icon()
    def self.icon()
        "✨"
    end

    # NxProjects::toString(item)
    def self.toString(item)
        "#{NxProjects::icon()} #{item["description"]}"
    end

    # NxProjects::listingItems()
    def self.listingItems()
        Items::mikuType("NxProject")
    end
end
