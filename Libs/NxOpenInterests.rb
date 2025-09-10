
class NxOpenInterests

    # NxOpenInterests::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::init(uuid)
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "mikuType", "NxOpenInterest")
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxOpenInterests::toString(item)
    def self.toString(item)
        "☯︎ #{item["description"]}"
    end

    # NxOpenInterests::listingItems()
    def self.listingItems()
        Items::mikuType("NxOpenInterest")
    end
end
