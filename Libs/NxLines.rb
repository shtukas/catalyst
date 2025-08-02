
class NxLines

    # NxLines::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Index3::init(uuid)
        Index3::setAttribute(uuid, "mikuType", "NxLine")
        Index3::setAttribute(uuid, "unixtime", Time.new.to_i)
        Index3::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Index3::setAttribute(uuid, "description", description)
        Index3::itemOrNull(uuid)
    end

    # NxLines::interactivelyIssueNew(uuid, description)
    def self.interactivelyIssueNew(uuid, description)
        uuid = uuid || SecureRandom.uuid
        Index3::init(uuid)
        Index3::setAttribute(uuid, "mikuType", "NxLine")
        Index3::setAttribute(uuid, "unixtime", Time.new.to_i)
        Index3::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Index3::setAttribute(uuid, "description", description)
        Index3::itemOrNull(uuid)
    end

    # NxLines::locationToLine(description, location)
    def self.locationToLine(description, location)
        uuid = SecureRandom.uuid
        Index3::init(uuid)
        payload = UxPayload::locationToPayload(uuid, location)
        Index3::setAttribute(uuid, "mikuType", "NxLine")
        Index3::setAttribute(uuid, "unixtime", Time.new.to_i)
        Index3::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Index3::setAttribute(uuid, "description", description)
        Index3::setAttribute(uuid, "uxpayload-b4e4", payload)
        Index3::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxLines::toString(item)
    def self.toString(item)
        "✒️  #{item["description"]}"
    end

    # NxLines::listingItems()
    def self.listingItems()
        Index1::mikuTypeItems("NxLine")
    end
end
