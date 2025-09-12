
class NxEvents

    # NxEvents::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", datetime)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "mikuType", "NxEvent")
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxEvents::icon(item)
    def self.icon(item)
        "🗓️ "
    end

    # NxEvents::toString(item)
    def self.toString(item)
        "#{NxEvents::icon(item)} [#{item["datetime"]}] #{item["description"]}"
    end

    # NxEvents::listingItems()
    def self.listingItems()
        Items::mikuType("NxEvent")
    end
end
