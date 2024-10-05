
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull()
        taskType = NxTasks::interactivelyIssueDxTaskType()
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "taskType-11", taskType)
        Items::itemOrNull(uuid)
    end

    # NxTasks::interactivelyIssueNewOrNullWithTaskType(taskType)
    def self.interactivelyIssueNewOrNullWithTaskType(taskType)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull()
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "taskType-11", taskType)
        Items::itemOrNull(uuid)
    end

    # NxTasks::descriptionToTask1(description)
    def self.descriptionToTask1(description)
        uuid = SecureRandom.hex
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxTasks::icon(item)
    def self.icon(item)
        if item["taskType-11"]["variant"] == "on date" then
            return "🗓️ "
        end
        if item["taskType-11"]["variant"] == "general time commitment" then
            return "⏱️ "
        end
        if item["taskType-11"]["variant"] == "task with time commitment" then
            return "🔺"
        end
        if item["taskType-11"]["variant"] == "tail" then
            return "🔹"
        end
        
    end

    # NxTasks::ratio(item)
    def self.ratio(item)
        if item["taskType-11"]["hoursPerWeek"].nil? then
            raise "cannot compute NxTasks::ratio for item: #{item}"
        end
        hours = item["taskType-11"]["hoursPerWeek"].to_f
        [Bank1::recoveredAverageHoursPerDay(item["uuid"]), 0].max.to_f/(hours/7)
    end

    # NxTasks::ratioString(item)
    def self.ratioString(item)
        "(#{"%6.2f" % (100 * NxTasks::ratio(item))} %; #{"%5.2f" % item["taskType-11"]["hoursPerWeek"]} h/w)".yellow
    end

    # NxTasks::taskTypeToString(item)
    def self.taskTypeToString(item)
        if item["taskType-11"]["variant"] == "on date" then
            return "[#{item["taskType-11"]["date"]}]"
        end
        if item["taskType-11"]["variant"] == "general time commitment" then
            return NxTasks::ratioString(item)
        end
        if item["taskType-11"]["variant"] == "task with time commitment" then
            return NxTasks::ratioString(item)
        end
        if item["taskType-11"]["variant"] == "tail" then
            return "(#{"%6.2f" % item["taskType-11"]["position"]})"
        end
    end

    # NxTasks::toString(item, context)
    def self.toString(item, context = nil)
        "#{NxTasks::icon(item)} #{NxTasks::taskTypeToString(item)} #{item["description"]}"
    end

    # NxTasks::dated()
    def self.dated()
        Items::mikuType("NxTask")
            .select{|item| item["taskType-11"]["variant"] == "on date" }
            .select{|item| item["taskType-11"]["date"] <= CommonUtils::today() }
            .sort_by{|item| item["unixtime"] }
    end

    # NxTasks::managed()
    def self.managed()
        Items::mikuType("NxTask")
            .select{|item| item["taskType-11"]["variant"] == "general time commitment" or item["taskType-11"]["variant"] == "task with time commitment" }
            .sort_by{|item| NxTasks::ratio(item) }
            .select{|item| NxTasks::ratio(item) < 1 }
    end

    # NxTasks::tail(cardinal)
    def self.tail(cardinal)
        Items::mikuType("NxTask")
            .select{|item| item["taskType-11"]["variant"] == "tail" }
            .sort_by{|item| item["taskType-11"]["position"] }
            .first(cardinal)
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

    # NxTasks::interactivelyIssueDxTaskType()
    def self.interactivelyIssueDxTaskType()
        variants = [
            "on date",
            "general time commitment",
            "task with time commitment",
            "tail (with precise positioning)"
        ]
        variant = nil
        loop {
            variant = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", variants)
            break if !variant.nil?
        }
        if variant == "on date" then
            datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
            date = datetime[0, 10]
            return {
                "variant"  => "on date",
                "date"     => date
            }
        end
        if variant == "general time commitment" then
            hours = LucilleCore::askQuestionAnswerAsString("hours (per week): ").to_f
            return {
                "variant"      => "general time commitment",
                "hoursPerWeek" => hours
            }
        end
        if variant == "task with time commitment" then
            hours = LucilleCore::askQuestionAnswerAsString("hours (per week): ").to_f
            return {
                "variant"      => "task with time commitment",
                "hoursPerWeek" => hours
            }
        end
        if variant == "tail (with precise positioning)" then
            options = ["absolute first", "between 10 and 20", "absolute last"]
            option = nil
            loop {
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
                break if !option.nil?
            }
            if option == "absolute first" then
                return {
                    "variant"  => "tail",
                    "position" => NxTasks::firstTailPosition() - 1
                }
            end
            if option == "between 10 and 20" then
                return {
                    "variant"  => "tail",
                    "position" => 0 # TODO
                }
            end
            if option == "absolute last" then
                return {
                    "variant"  => "tail",
                    "position" => NxTasks::lastTailPosition() + 1
                }
            end
        end
    end

    # NxTasks::interactivelySelectManagedOrNull()
    def self.interactivelySelectManagedOrNull()
        items = Items::mikuType("NxTask")
                    .select{|item| item["taskType-11"]["variant"] == "general time commitment" or item["taskType-11"]["variant"] == "task with time commitment" }
                    .sort_by{|item| NxTasks::ratio(item) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", items, lambda{|item| PolyFunctions::toString(item) })
    end

end
