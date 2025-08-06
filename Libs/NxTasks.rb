
class NxTasks

    # ------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Items::init(uuid)
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::itemOrNull(uuid)
    end

    # NxTasks::locationToTask(description, location)
    def self.locationToTask(description, location)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        payload = UxPayload::locationToPayload(uuid, location)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask(description)
    def self.descriptionToTask(description)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTasks::icon(item)
    def self.icon(item)
        "🔹"
    end

    # NxTasks::toString(item)
    def self.toString(item)
        parent = Parenting::childuuidToParentOrNull(item["uuid"])
        if parent then
            position = Parenting::childPositionAtParentOrZero(parent["uuid"], item["uuid"])
            px2 = " (#{position} @ #{parent["description"]})".yellow
        else
            px2 = " (orphan)".yellow
        end
        "#{NxTasks::icon(item)} #{item["description"]}#{px2}"
    end

    # ------------------
    # Ops

    # NxTasks::performItemPositioning(itemuuid)
    def self.performItemPositioning(itemuuid)
        parentuuid, position = Operations::decideParentAndPosition()
        Parenting::insertEntry(parentuuid, itemuuid, position)
        ListingDatabase::listOrRelist(parentuuid)
    end

    # NxTasks::maintenance()
    def self.maintenance()
        count1 = Items::mikuType("NxTask")
                    .select{|item| Parenting::childuuidToParentUuidOrNull(item["uuid"]) == NxCores::infinityuuid() }
                    .size
        #puts "count1: #{count1}"
        iced = Items::mikuType("NxIce")
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
