
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
        Items::setAttribute(uuid, "priorityLevel48", PriorityLevels::interactivelySelectOne())
        Items::setAttribute(uuid, "mikuType", "NxTask")
        Items::itemOrNull(uuid)
    end

    # NxTasks::locationToTask(description, location, priorityLevel48)
    def self.locationToTask(description, location, priorityLevel48)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        payload = UxPayload::locationToPayload(uuid, location)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "priorityLevel48", priorityLevel48)
        Items::setAttribute(uuid, "mikuType", "NxTask")
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
        pl = "(#{item["priorityLevel48"]})".yellow
        "#{NxTasks::icon(item)} #{item["description"]} #{pl}"
    end

    # ------------------
    # Ops

    # NxTasks::maintenance()
    def self.maintenance()
        size1 = Items::mikuType("NxTask").size
        if size1 < 100 then
            Items::mikuType("NxIce").take(100 - size1).each{|item|
                puts "moving from NxIce to NxTask: #{item["description"]}"
                Items::setAttribute(item["uuid"], "priorityLevel48", "low")
                Items::setAttribute(item["uuid"], "mikuType", "NxTask")
            }
        end
    end
end
