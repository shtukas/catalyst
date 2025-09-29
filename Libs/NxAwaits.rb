
class NxAwaits

    # NxAwaits::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "mikuType", "NxAwait")
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxAwaits::icon(item)
    def self.icon(item)
        "😴"
    end

    # NxAwaits::toString(item)
    def self.toString(item)
        "#{NxAwaits::icon(item)} #{item["description"]}"
    end

    # NxAwaits::listingItems()
    def self.listingItems()
        Items::mikuType("NxAwait")
    end
end
