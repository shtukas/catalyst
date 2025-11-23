
# encoding: UTF-8

class NxSequenceItem

    # ---------------------------------------
    # Maker

    # NxSequenceItem::interactivelyIssueNewOrNull(sequenceuuid, ordinal)
    def self.interactivelyIssueNewOrNull(sequenceuuid, ordinal)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        payload = UxPayload::makeNewPayloadOrNull(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "sequenceuuid", sequenceuuid)
        Items::setAttribute(uuid, "ordinal", ordinal)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "mikuType", "NxSequenceItem")
        item = Items::itemOrNull(uuid)
        Fsck::fsckOrError(item)
        item
    end

    # ---------------------------------------
    # Data

    # NxSequenceItem::toString(item)
    def self.toString(item)
        "(sequence item) #{item["description"]}#{UxPayload::suffixString(item)}"
    end

end
