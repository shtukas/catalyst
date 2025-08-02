
class NxFloats

    # NxFloats::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Index3::init(uuid)
        Index3::setAttribute(uuid, "mikuType", "NxFloat")
        Index3::setAttribute(uuid, "unixtime", Time.new.to_i)
        Index3::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Index3::setAttribute(uuid, "description", description)
        Index3::itemOrNull(uuid)
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
