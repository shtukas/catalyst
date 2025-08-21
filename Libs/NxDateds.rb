
class NxDateds

    # NxDateds::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCodeOrNull()
        return nil if datetime.nil?
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "date", datetime[0, 10])
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "mikuType", "NxDated")
        Items::itemOrNull(uuid)
    end

    # NxDateds::interactivelyIssueTodayOrNull()
    def self.interactivelyIssueTodayOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "date", CommonUtils::today())
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "mikuType", "NxDated")
        Items::itemOrNull(uuid)
    end

    # NxDateds::interactivelyIssueToday(description)
    def self.interactivelyIssueToday(description)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "date", CommonUtils::today())
        Items::setAttribute(uuid, "mikuType", "NxDated")
        Items::itemOrNull(uuid)
    end

    # NxDateds::interactivelyIssueTomorrowOrNull()
    def self.interactivelyIssueTomorrowOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "date", (Time.new + 86400).to_s[0, 10])
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "mikuType", "NxDated")
        Items::itemOrNull(uuid)
    end

    # NxDateds::interactivelyIssueAtGivenDateOrNull(date)
    def self.interactivelyIssueAtGivenDateOrNull(date)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "date", date)
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "mikuType", "NxDated")
        Items::itemOrNull(uuid)
    end

    # NxDateds::locationToItem(description, location)
    def self.locationToItem(description, location)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "date", CommonUtils::today())
        payload = UxPayload::locationToPayload(uuid, location)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "mikuType", "NxDated")
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxDateds::icon(item)
    def self.icon(item)
        "🗓️ "
    end

    # NxDateds::toString(item)
    def self.toString(item)
        "#{NxDateds::icon(item)} [#{item["date"][0, 10]}] (-> #{"%7.3f" % (item["position-0836"] || 0)}) #{item["description"]}"
    end

    # NxDateds::listingItemsInOrder()
    def self.listingItemsInOrder()
        items = Items::mikuType("NxDated")
            .select{|item| item["date"][0, 10] <= CommonUtils::today() }
            .sort_by{|item| item["position-0836"] || 0 }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # NxDateds::firstPosition()
    def self.firstPosition()
        ([0] + Items::mikuType("NxDated").map{|item| item["position-0836"] || 0 }).min
    end

    # ---------------
    # Ops

    # NxDateds::redate(item, datetime = nil)
    def self.redate(item, datetime = nil)
        NxBalls::stop(item)
        datetime = datetime || CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        Items::setAttribute(item["uuid"], "date", datetime)
    end

    # NxDateds::sort()
    def self.sort()
        items = NxDateds::listingItemsInOrder()
        selected, _ = LucilleCore::selectZeroOrMore("dateds", [], items, lambda{|i| PolyFunctions::toString(i) })
        selected.reverse.each{|item|
            position = NxDateds::firstPosition() - 1
            Items::setAttribute(item["uuid"], "position-0836", position)
        }
    end
end
