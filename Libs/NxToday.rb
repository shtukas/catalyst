
class NxTodays

    # NxTodays::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull())
        Items::setAttribute(uuid, "mikuType", "NxToday")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxTodays::icon()
    def self.icon()
        "☀️"
    end

    # NxTodays::toString(item)
    def self.toString(item)
        "#{NxTodays::icon()} #{item["description"]}"
    end
end
