
class NxPriorities

    # NxPriorities::issue(description, position)
    def self.issue(description, position)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "position-09", position)
        Items::setAttribute(uuid, "mikuType", "NxPriority")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxPriorities::icon()
    def self.icon()
        "🖋️ "
    end

    # NxPriorities::toString(item)
    def self.toString(item)
        "#{NxPriorities::icon()} #{item["description"]}"
    end
end
