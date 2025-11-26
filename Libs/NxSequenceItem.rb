
# encoding: UTF-8

class NxSequenceItem

    # ---------------------------------------
    # Maker

    # NxSequenceItem::interactivelyIssueNewGetReferenceOrNull(sequenceuuid, ordinal)
    def self.interactivelyIssueNewGetReferenceOrNull(sequenceuuid, ordinal)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        payload = UxPayloads::makeNewPayloadOrNull()
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "sequenceuuid", sequenceuuid)
        Items::setAttribute(uuid, "ordinal", ordinal)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-uuid-1141", payload ? payload["uuid"] : nil)
        Items::setAttribute(uuid, "mikuType", "NxSequenceItem")
        item = Items::objectOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # ---------------------------------------
    # Data

    # NxSequenceItem::toString(item)
    def self.toString(item)
        "(sequence item) #{item["description"]}#{UxPayloads::suffixString(item)}"
    end

end
