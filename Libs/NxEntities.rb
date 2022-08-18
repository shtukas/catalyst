
# encoding: UTF-8

class NxEntities

    # ----------------------------------------------------------------------
    # IO

    # NxEntities::items()
    def self.items()
        Fx256WithCache::mikuTypeToItems("NxEntity")
    end

    # NxEntities::destroy(uuid)
    def self.destroy(uuid)
        Fx256::deleteObjectLogically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxEntities::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Fx18Attributes::setJsonEncoded(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncoded(uuid, "mikuType",    "NxEntity")
        Fx18Attributes::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setJsonEncoded(uuid, "description", description)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        Fx256::broadcastObjectEvents(uuid)
        item = Fx256::getProtoItemOrNull(uuid)
        if item.nil? then
            raise "(error: 291521ea-221b-4a81-9b6e-9ef0925d2ca5) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxEntities::toString(item)
    def self.toString(item)
        "(entity) #{item["description"]}"
    end
end
