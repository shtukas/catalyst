
class NxFloats

    # NxFloats::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::init(uuid)
        Items::setAttribute(uuid, "mikuType", "NxFloat")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxFloats::toString(item)
    def self.toString(item)
        "🐠 #{item["description"]}"
    end

    # NxFloats::listingItems()
    def self.listingItems()
        Index1::mikuTypeItems("NxFloat")
    end
end
