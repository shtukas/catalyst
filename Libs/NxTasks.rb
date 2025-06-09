
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull(nx1949 = nil)
    def self.interactivelyIssueNewOrNull(nx1949 = nil)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        nx1949 = nx1949 || Operations::makeNx1949OrNull()
        nx1609 = NxTasks::interactivelyMakeNx1609OrNull()
        Items::init(uuid)
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "nx1949", nx1949)
        Items::setAttribute(uuid, "nx1609", nx1609)
        Items::itemOrNull(uuid)
    end

    # NxTasks::locationToTask(description, location, nx1949)
    def self.locationToTask(description, location, nx1949)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        payload = UxPayload::locationToPayload(uuid, location)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "nx1949", nx1949)
        Items::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask(description, nx1949)
    def self.descriptionToTask(description, nx1949)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "nx1949", nx1949)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Standard Items

    # NxTasks::icon(item)
    def self.icon(item)
        return "🔺" if item["nx1609"]
        "🔹"
    end

    # NxTasks::toString(item, context)
    def self.toString(item, context = nil)
        px1 = item["nx1609"] ? " (#{NxTasks::activeItemRatio(item)})".yellow : ''
        core = Items::itemOrNull(item["nx1949"]["parentuuid"]) # we assume that it's not null
        px2 = " (#{item["nx1949"]["position"]} @ #{core["description"]})".yellow
        "#{NxTasks::icon(item)} #{item["description"]}#{px1}#{px2}"
    end

    # NxTasks::itemsInPositionOrder()
    def self.itemsInPositionOrder()
        Items::mikuType("NxTask")
            .sort_by{|item| item["nx1949"]["position"] }
    end

    # ------------------
    # Active Items

    # NxTasks::interactivelyMakeNx1609OrNull()
    def self.interactivelyMakeNx1609OrNull()
        hours = LucilleCore::askQuestionAnswerAsString("(active ?) hours per day (empty for none): ")
        return nil if hours == ""
        hours = hours.to_f
        return nil if hours == 0
        {
            "hours" => hours
        }
    end

    # NxTasks::activeItemRatio(item)
    def self.activeItemRatio(item)
        Bank1::recoveredAverageHoursPerDay(item["uuid"]).to_f/item["nx1609"]["hours"]
    end

    # NxTasks::activeItems()
    def self.activeItems()
        Items::mikuType("NxTask")
            .select{|item| item["nx1609"] }
    end

    # NxTasks::activeItemsInRatioOrder()
    def self.activeItemsInRatioOrder()
        NxTasks::activeItems()
            .sort_by{|item| NxTasks::activeItemRatio(item) }
    end

    # NxTasks::activeItemsForListing()
    def self.activeItemsForListing()
        NxTasks::activeItemsInRatioOrder()
            .select{|item| NxTasks::activeItemRatio(item) < 1 }
    end

    # ------------------
    # Ops

    # NxTasks::performItemPositioning(item)
    def self.performItemPositioning(item)
        nx1949 = Operations::makeNx1949OrNull()
        return if nx1949.nil?
        Items::setAttribute(item["uuid"], "nx1949", nx1949)
    end
end
