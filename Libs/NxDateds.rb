
class NxDateds

    # NxDateds::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Index3::init(uuid)
        Index3::setAttribute(uuid, "unixtime", Time.new.to_i)
        Index3::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Index3::setAttribute(uuid, "description", description)
        Index3::setAttribute(uuid, "date", datetime[0, 10])
        payload = UxPayload::makeNewOrNull(uuid)
        Index3::setAttribute(uuid, "uxpayload-b4e4", payload)
        Index3::setAttribute(uuid, "mikuType", "NxDated")
        Index3::itemOrNull(uuid)
    end

    # NxDateds::interactivelyIssueTodayOrNull()
    def self.interactivelyIssueTodayOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Index3::init(uuid)
        Index3::setAttribute(uuid, "unixtime", Time.new.to_i)
        Index3::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Index3::setAttribute(uuid, "description", description)
        Index3::setAttribute(uuid, "date", CommonUtils::today())
        payload = UxPayload::makeNewOrNull(uuid)
        Index3::setAttribute(uuid, "uxpayload-b4e4", payload)
        Index3::setAttribute(uuid, "mikuType", "NxDated")
        Index3::itemOrNull(uuid)
    end

    # NxDateds::interactivelyIssueTomorrowOrNull()
    def self.interactivelyIssueTomorrowOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Index3::init(uuid)
        Index3::setAttribute(uuid, "unixtime", Time.new.to_i)
        Index3::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Index3::setAttribute(uuid, "description", description)
        Index3::setAttribute(uuid, "date", (Time.new + 86400).to_s[0, 10])
        payload = UxPayload::makeNewOrNull(uuid)
        Index3::setAttribute(uuid, "uxpayload-b4e4", payload)
        Index3::setAttribute(uuid, "mikuType", "NxDated")
        Index3::itemOrNull(uuid)
    end

    # NxDateds::interactivelyIssueAtGivenDateOrNull(date)
    def self.interactivelyIssueAtGivenDateOrNull(date)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Index3::init(uuid)
        Index3::setAttribute(uuid, "unixtime", Time.new.to_i)
        Index3::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Index3::setAttribute(uuid, "description", description)
        Index3::setAttribute(uuid, "date", date)
        payload = UxPayload::makeNewOrNull(uuid)
        Index3::setAttribute(uuid, "uxpayload-b4e4", payload)
        Index3::setAttribute(uuid, "mikuType", "NxDated")
        Index3::itemOrNull(uuid)
    end

    # NxDateds::locationToItem(description, location)
    def self.locationToItem(description, location)
        uuid = SecureRandom.uuid
        Index3::init(uuid)
        Index3::setAttribute(uuid, "unixtime", Time.new.to_i)
        Index3::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Index3::setAttribute(uuid, "description", description)
        Index3::setAttribute(uuid, "date", CommonUtils::today())
        payload = UxPayload::locationToPayload(uuid, location)
        Index3::setAttribute(uuid, "uxpayload-b4e4", payload)
        Index3::setAttribute(uuid, "mikuType", "NxDated")
        Index3::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxDateds::toString(item)
    def self.toString(item)
        "🗓️  [#{item["date"][0, 10]}] #{item["description"]}"
    end

    # NxDateds::listingItems()
    def self.listingItems()
        items = Index1::mikuTypeItems("NxDated")
            .select{|item| item["date"][0, 10] <= CommonUtils::today() }
            .sort_by{|item| item["unixtime"] }
    end

    # ---------------
    # Ops

    # NxDateds::redate(item, datetime = nil)
    def self.redate(item, datetime = nil)
        NxBalls::stop(item)
        datetime = datetime || CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        Index3::setAttribute(item["uuid"], "date", datetime)
    end
end
