
class NxMiniProjects

    # NxMiniProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Items::itemInit(uuid, "NxMiniProject")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", UxPayload::makeNewOrNull())
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxMiniProjects::icon(item)
    def self.icon(item)
        "🔺"
    end

    # NxMiniProjects::toString(item)
    def self.toString(item)
        "#{NxMiniProjects::icon(item)} (#{"%6.3f" % Bank1::recoveredAverageHoursPerDay(item["uuid"])}) #{item["description"]}"
    end

    # NxMiniProjects::shouldDisplay()
    def self.shouldDisplay()
        Bank1::recoveredAverageHoursPerDay("FEF32089-A7B8-4ADF-8565-B8224E405287") < 2
    end

    # NxMiniProjects::listingItems()
    def self.listingItems()
        return [] if !NxMiniProjects::shouldDisplay()
        Items::mikuType("NxMiniProject")
            .select{|item| Listing::listable(item) }
            .sort_by{|item| item["unixtime"] }
            .take(3)
            .sort_by{|item| Bank1::recoveredAverageHoursPerDay(item["uuid"]) }
    end

    # ------------------
    # Operations

    # NxMiniProjects::transformToMini(item)
    def self.transformToMini(item)
        if item["mikuType"] == "Wave" then
            uuid = SecureRandom.uuid
            Items::itemInit(uuid, "NxMiniProject")
            Items::setAttribute(uuid, "unixtime", Time.new.to_i)
            Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
            Items::setAttribute(uuid, "description", item["description"])
            Items::setAttribute(uuid, "uxpayload-b4e4", item["uxpayload-b4e4"])
            Waves::performWaveDone(item)
            return
        end
        if item["mikuType"] == "NxOndate" then
            Items::setAttribute(item["uuid"], "mikuType", "NxMiniProject")
            Items::setAttribute(item["uuid"], "unixtime", Time.new.to_i)
            Items::setAttribute(item["uuid"], "datetime", Time.new.utc.iso8601)
            return
        end
        raise "(error: 2F279A66) cannot NxMiniProjects::transformToMini item: #{item}"
    end
end
