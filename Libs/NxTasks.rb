
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull(nx1949 = nil)
    def self.interactivelyIssueNewOrNull(nx1949 = nil)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        nx1949 = nx1949 || Operations::makeNx1949OrNull()
        Items::init(uuid)
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "nx1949", nx1949)
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
        return "🔺" if item["nx2290-important"]
        "🔹"
    end

    # NxTasks::toString(item, context)
    def self.toString(item, context = nil)
        core = Items::itemOrNull(item["nx1949"]["parentuuid"]) # we assume that it's not null
        px2 = " (#{item["nx1949"]["position"]} @ #{core["description"]})".yellow
        "#{NxTasks::icon(item)} #{item["description"]}#{px2}"
    end

    # NxTasks::itemsInPositionOrder()
    def self.itemsInPositionOrder()
        Items::mikuType("NxTask")
            .sort_by{|item| item["nx1949"]["position"] }
    end

    # ------------------
    # Active Items

    # NxTasks::importantItems()
    def self.importantItems()
        Items::mikuType("NxTask")
            .select{|item| item["nx2290-important"] }
    end

    # NxTasks::importantItemsForListing()
    def self.importantItemsForListing()
        return [] if Time.new.hour >= 17
        NxTasks::importantItems()
            .select{|item| Bank1::recoveredAverageHoursPerDay(item["uuid"]) < 1 }
            .sort_by{|item| Bank1::recoveredAverageHoursPerDay(item["uuid"]) }
    end

    # NxTasks::listingItems()
    def self.listingItems()
        NxCores::cores()
            .select{|core| PolyFunctions::childrenForParent(core).size > 0 }
            .sort_by{|core| NxCores::ratio(core) }
            .select{|core| NxCores::ratio(core) < 1 }
            .map{|core| 
                PolyFunctions::childrenInOrder(core)
                .select{|item| !item["nx2290-important"] }
                .reduce([]){|selected, item|
                    if selected.size >= 3 then
                        selected
                    else
                        if NxBalls::itemIsActive(item) or Bank1::getValueAtDate(item["uuid"], CommonUtils::today()) < 3600 then
                            selected + [item]
                        else
                            selected
                        end
                    end
                }}
                .flatten
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
