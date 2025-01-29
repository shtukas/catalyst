
class NxFloats

    # NxFloats::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::itemInit(uuid, "NxFloat")
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
        Items::mikuType("NxFloat")
    end
end
