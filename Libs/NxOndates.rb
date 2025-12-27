
class NxOndates

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        date = CommonUtils::interactivelyMakeADate()
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        BladesFront::setAttribute(uuid, "unixtime", Time.new.to_i)
        BladesFront::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        BladesFront::setAttribute(uuid, "description", description)
        BladesFront::setAttribute(uuid, "date", date)
        BladesFront::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull(uuid))
        BladesFront::setAttribute(uuid, "mikuType", "NxOndate")
        item = Blades::itemOrNull(uuid)
        item
    end

    # NxOndates::interactivelyIssueNewWithDetails(description, date)
    def self.interactivelyIssueNewWithDetails(description, date)
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        BladesFront::setAttribute(uuid, "unixtime", Time.new.to_i)
        BladesFront::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        BladesFront::setAttribute(uuid, "description", description)
        BladesFront::setAttribute(uuid, "date", date)
        BladesFront::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull(uuid))
        BladesFront::setAttribute(uuid, "mikuType", "NxOndate")
        item = Blades::itemOrNull(uuid)
        item
    end

    # NxOndates::icon()
    def self.icon()
        "🗓️ "
    end

    # NxOndates::toString(item)
    def self.toString(item)
        "#{NxOndates::icon()} [#{item["date"]}] #{item["description"]}#{Parenting::suffix(item)}"
    end

    # NxOndates::listingItems()
    def self.listingItems()
        Blades::mikuType("NxOndate")
                .select{|item| item["date"] <= CommonUtils::today() }
                .sort_by{|item| item["unixtime"] }

    end
end
