
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
        Index2::insertEntry(parentuuid, uuid, position)
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
        "🔹"
    end

    # NxTasks::toString(item)
    def self.toString(item)
        parent = Index2::childuuidToParentOrDefaultInfinityCore(item["uuid"])
        position = Index2::childPositionAtParentOrZero(item["uuid"], parent["uuid"])
        px2 = " (#{position} @ #{parent["description"]})".yellow
        "#{NxTasks::icon(item)} #{item["description"]}#{px2}"
    end

    # ------------------
    # Ops

    # NxTasks::performItemPositioning(itemuuid)
    def self.performItemPositioning(itemuuid)
        parentuuid, position = Operations::decideParentAndPosition()
        Index2::insertEntry(parentuuid, itemuuid, position)
    end

    # NxTasks::maintenance()
    def self.maintenance()
        count1 = Index1::mikuTypeItems("NxTask")
                    .select{|item| Index2::childuuidToParentuuidOrNull(item["uuid"]) == NxCores::infinityuuid()}
                    .size
        #puts "count1: #{count1}"
        iced = Index1::mikuTypeItems("NxIce")
        count2 = iced.size
        #puts "count2: #{count2}"
        if count1 < 150 and count2 > 0 then
            iced.take(100).each{|item|
                puts "moving from NxIce to NxTask: #{item["description"]}"
                Items::setAttribute(item["uuid"], "mikuType", "NxTask")
            }
        end
    end
end
