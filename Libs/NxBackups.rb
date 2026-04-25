
class NxBackups

    # NxBackups::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        period = LucilleCore::askQuestionAnswerAsString("period in days: ").to_f
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "period", period)
        Items::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull())
        Items::setAttribute(uuid, "mikuType", "NxBackup")
        item = Items::itemOrNull(uuid)
        item
    end

    # NxBackups::icon()
    def self.icon()
        "💾"
    end

    # NxBackups::toString(item)
    def self.toString(item)
        "#{NxBackups::icon()} #{item["description"]} [every #{item["period"]} days]"
    end

    # NxBackups::listingItems()
    def self.listingItems()
        Items::mikuType("NxBackup")
    end
end
