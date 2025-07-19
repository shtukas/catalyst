
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        NxTasks::performItemPositioning(uuid)
        Items::init(uuid)
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::itemOrNull(uuid)
    end

    # NxTasks::interactivelyIssueNewOrNull2(parentuuid, position)
    def self.interactivelyIssueNewOrNull2(parentuuid, position)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Operations::registerChildInParent(parentuuid, uuid, position)
        Items::init(uuid)
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::itemOrNull(uuid)
    end

    # NxTasks::locationToTask(description, location, parentuuid, position)
    def self.locationToTask(description, location, parentuuid, position)
        uuid = SecureRandom.uuid
        Index2::insertEntry(parentuuid, uuid, position)
        Items::init(uuid)
        payload = UxPayload::locationToPayload(uuid, location)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask(description, parentuuid, position)
    def self.descriptionToTask(description, parentuuid, position)
        uuid = SecureRandom.uuid
        Index2::insertEntry(parentuuid, uuid, position)
        Items::init(uuid)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
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
        parent = Index2::childuuidToParentOrDefaultInfinityCore(item["uuid"])
        position = Index2::childPositionAtParentOrZero(item["uuid"], parent["uuid"])
        px2 = " (#{position} @ #{parent["description"]})".yellow
        "#{NxTasks::icon(item)} #{item["description"]}#{px2}"
    end

    # ------------------
    # Active Items

    # NxTasks::importantItems()
    def self.importantItems()
        Index1::mikuTypeItems("NxTask")
            .select{|item| item["nx2290-important"] }
    end

    # NxTasks::importantItemsForListing()
    def self.importantItemsForListing()
        NxTasks::importantItems()
            .select{|item| Bank1::recoveredAverageHoursPerDay(item["uuid"]) < 1 }
            .sort_by{|item| Bank1::recoveredAverageHoursPerDay(item["uuid"]) }
    end

    # NxTasks::listingItems()
    def self.listingItems()
        NxCores::cores()
            .select{|core| Index2::parentuuidToChildrenInOrder(core["uuid"]).size > 0 }
            .sort_by{|core| NxCores::ratio(core) }
            .select{|core| NxCores::ratio(core) < 1 }
            .map{|core| 
                Index2::parentuuidToChildrenInOrder(core["uuid"])
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

    # NxTasks::performItemPositioning(itemuuid)
    def self.performItemPositioning(itemuuid)
        parentuuid, position = Operations::decideParentAndPosition()
        Operations::registerChildInParent(parentuuid, itemuuid, position)
    end
end
