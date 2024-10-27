
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull(uuid)
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::itemOrNull(uuid)
    end

    # NxTasks::locationToTailTask1(location, position)
    def self.locationToTailTask1(location, position)
        uuid = SecureRandom.hex
        nhash = AionCore::commitLocationReturnHash(Elizabeth.new(uuid), location)
        payload = {
            "type" => "aion-point",
            "nhash" => nhash
        }
        taskType = {
            "variant"  => "tail",
            "position" => position
        }
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", File.basename(location))
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "taskType-11", taskType)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTasks::taskTypeToString(item)
    def self.taskTypeToString(item)
        if item["taskType-11"]["variant"] == "on date" then
            return "[#{item["taskType-11"]["date"]}]"
        end
        if item["taskType-11"]["variant"] == "tail" then
            return "(#{"%6.2f" % item["taskType-11"]["position"]})"
        end
    end

    # NxTasks::toString(item, context)
    def self.toString(item, context = nil)
        "#{NxTasks::icon(item)} #{NxTasks::taskTypeToString(item)} #{item["description"]}"
    end

    # NxTasks::firstTailPosition()
    def self.firstTailPosition()
        item = Items::mikuType("NxTask")
                .select{|item| item["taskType-11"]["variant"] == "tail" }
                .sort_by{|item| item["taskType-11"]["position"] }
                .first
        return 1 if item.nil?
        item["taskType-11"]["position"]
    end

    # NxTasks::lastTailPosition()
    def self.lastTailPosition()
        item = Items::mikuType("NxTask")
                .select{|item| item["taskType-11"]["variant"] == "tail" }
                .sort_by{|item| item["taskType-11"]["position"] }
                .last
        return 1 if item.nil?
        item["taskType-11"]["position"]
    end

    # NxTasks::between10And20Position()
    def self.between10And20Position()
        items = Items::mikuType("NxTask")
                .select{|item| item["taskType-11"]["variant"] == "tail" }
                .sort_by{|item| item["taskType-11"]["position"] }
        items = items.drop(10).take(10)
        if items.size == 0 then
            return 1
        end
        if items.size <= 10 then
            return (items.last["taskType-11"]["position"] + 1).floor
        end
        a = items.first["taskType-11"]["position"]
        b = items.last["taskType-11"]["position"]
        a + rand * (b - 1)
    end

    # -------------------------------------

    # NxTasks::listingItems()
    def self.listingItems()
        Items::mikuType("NxTask")
            .sort_by{|item| item["global-positioning"] }
            .take(10)
    end
end
