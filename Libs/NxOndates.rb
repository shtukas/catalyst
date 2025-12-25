
class NxOndates

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        date = CommonUtils::interactivelyMakeADate()
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "date", date)
        Items::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull())
        Items::setAttribute(uuid, "mikuType", "NxOndate")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxOndates::interactivelyIssueNewWithDetails(description, date)
    def self.interactivelyIssueNewWithDetails(description, date)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "date", date)
        Items::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull())
        Items::setAttribute(uuid, "mikuType", "NxOndate")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxOndates::icon()
    def self.icon()
        "🗓️ "
    end

    # NxOndates::toString(item)
    def self.toString(item)
        "#{NxOndates::icon()} [#{item["date"]}] #{item["description"]}"
    end

    # NxOndates::listingItems()
    def self.listingItems()
        Items::mikuType("NxOndate")
                .select{|item| item["date"] <= CommonUtils::today() }
                .sort_by{|item| item["unixtime"] }

    end
end
