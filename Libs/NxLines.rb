
class NxLines

    # NxLines::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::init(uuid)
        Items::setAttribute(uuid, "mikuType", "NxLine")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::itemOrNull(uuid)
    end

    # NxLines::interactivelyIssueNew(uuid, description)
    def self.interactivelyIssueNew(uuid, description)
        uuid = uuid || SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "mikuType", "NxLine")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::itemOrNull(uuid)
    end

    # NxLines::locationToLine(description, location)
    def self.locationToLine(description, location)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        payload = UxPayload::locationToPayload(uuid, location)
        Items::setAttribute(uuid, "mikuType", "NxLine")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::itemOrNull(uuid)
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
