
class NxBackups

    # NxBackups::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        period = LucilleCore::askQuestionAnswerAsString("period in days: ").to_f
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "period", period)
        Blades::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull(uuid))
        Blades::setAttribute(uuid, "mikuType", "NxBackup")
        item = Blades::itemOrNull(uuid)
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
        Blades::mikuType("NxBackup")
    end

    # NxBackups::listingPosition(item)
    def self.listingPosition(item)
        0.400
    end
end
