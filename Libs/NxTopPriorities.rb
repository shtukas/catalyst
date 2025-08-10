
class NxTopPriorities

    # NxTopPriorities::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        payload = UxPayload::makeNewOrNull(uuid)
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "mikuType", "NxTopPriority")
        Items::itemOrNull(uuid)
    end

    # NxTopPriorities::issueNewNoPayload(description)
    def self.issueNewNoPayload(description)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "mikuType", "NxTopPriority")
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTopPriorities::toString(item)
    def self.toString(item)
        "🔥 #{item["description"]}"
    end

    # NxTopPriorities::listingItems()
    def self.listingItems()
        Items::mikuType("NxTopPriority")
    end
end
