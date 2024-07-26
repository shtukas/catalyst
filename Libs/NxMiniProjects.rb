
class NxMiniProjects

    # ------------------
    # Data

    # NxMiniProjects::icon(item)
    def self.icon(item)
        "🔺"
    end

    # NxMiniProjects::toString(item)
    def self.toString(item)
        "#{NxMiniProjects::icon(item)} #{item["description"]}"
    end

    # NxMiniProjects::shouldDisplay()
    def self.shouldDisplay()
        true
    end

    # NxMiniProjects::listingItems()
    def self.listingItems()
        return [] if !NxMiniProjects::shouldDisplay()
        Items::mikuType("NxMiniProject")
            .sort_by{|item| item["unixtime"] }
            .take(3)
            .sort_by{|item| Bank1::recoveredAverageHoursPerDay(item["uuid"]) }
    end

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
            Items::itemInit(item["uuid"], "NxMiniProject")
            return
        end
        raise "(error: 2F279A66) cannot NxMiniProjects::transformToMini item: #{item}"
    end
end
