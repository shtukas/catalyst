
class NxTasks

    # ------------------
    # Makers

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::init(uuid)
        payload = UxPayload::makeNewOrNull(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::itemOrNull(uuid)
    end

    # NxTasks::locationToTask(description, location)
    def self.locationToTask(description, location)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        payload = UxPayload::locationToPayload(uuid, location)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask(description)
    def self.descriptionToTask(description)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTasks::icon(item)
    def self.icon(item)
        if Parenting::parentOrNull(item["uuid"]).nil? then
            return "▫️ "
        end
        "🔹"
    end

    # NxTasks::toString(item)
    def self.toString(item)
        parentingSuffix = Parenting::suffix(item)
        "#{NxTasks::icon(item)} #{item["description"]}#{parentingSuffix}"
    end

    # NxTasks::isOrphan(item)
    def self.isOrphan(item)
        Parenting::parentOrNull(item["uuid"]).nil?
    end

    # NxTasks::orphan()
    def self.orphan()
        Items::mikuType("NxTask")
            .select{|item| NxTasks::isOrphan(item) }
    end

    # ------------------
    # Ops

    # NxTasks::performItemPositioning(itemuuid)
    def self.performItemPositioning(itemuuid)
        data = Operations::architectParentAndPosition()
        Parenting::insertEntry(data["parent"]["uuid"], itemuuid, data["position"])
        ListingService::evaluate(itemuuid)
    end

    # NxTasks::maintenance()
    def self.maintenance()
        NxTasks::orphan().each{|item|
            if item["priorityLevel47"].nil? then
                puts PolyFunctions::toString(item)
                Items::setAttribute(item["uuid"], "priorityLevel47", PriorityLevels::interactivelySelectOne())
            end
        }
        count1 = Items::mikuType("NxTask")
                    .select{|item| Parenting::parentUuidOrNull(item["uuid"]) == NxThreads::infinityuuid() }
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
