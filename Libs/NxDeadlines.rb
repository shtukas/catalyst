
class NxDeadlines

    # NxDeadlines::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "date", CommonUtils::interactivelyMakeADateOrNull())
        Items::setAttribute(uuid, "mikuType", "NxDeadline")
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxDeadlines::icon(item)
    def self.icon(item)
        "⏱️ "
    end

    # NxDeadlines::toString(item)
    def self.toString(item)
        "#{NxDeadlines::icon(item)} #{item["description"]}"
    end

    # NxDeadlines::listingItems()
    def self.listingItems()
        Items::mikuType("NxDeadline")
    end
end
