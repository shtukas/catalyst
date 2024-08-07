
class NxOndates

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        Items::itemInit(uuid, "NxOndate")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", datetime)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", UxPayload::makeNewOrNull())
        Items::itemOrNull(uuid)
    end

    # NxOndates::interactivelyIssueAtDatetimeNewOrNull(datetime)
    def self.interactivelyIssueAtDatetimeNewOrNull(datetime)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::itemInit(uuid, "NxOndate")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", datetime)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", UxPayload::makeNewOrNull())
        Items::itemOrNull(uuid)
    end

    # NxOndates::interactivelyIssueAtTodayFromDescription(description)
    def self.interactivelyIssueAtTodayFromDescription(description)
        uuid = SecureRandom.uuid
        Items::itemInit(uuid, "NxOndate")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", CommonUtils::today())
        Items::setAttribute(uuid, "description", description)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxOndates::toString(item)
    def self.toString(item)
        "🗓️  #{item["description"]}"
    end

    # NxOndates::listingItems()
    def self.listingItems()
        Items::mikuType("NxOndate")
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
            .sort_by{|item| item["unixtime"] }
    end
end
