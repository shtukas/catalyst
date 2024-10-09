
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        payload = UxPayload::makeNewOrNull(uuid)
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
        payload = UxPayload::makeNewOrNull(uuid)
        Items::itemInit(uuid, "NxTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "taskType-11", taskType)
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

    # NxTasks::isTimeCommitment(item)
    def self.isTimeCommitment(item)
        item["taskType-11"]["variant"] == "general time commitment" or item["taskType-11"]["variant"] == "task with time commitment" 
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
            .select{|item| NxTasks::isTimeCommitment(item) }
            .sort_by{|item| NxTasks::ratio(item) }
            .select{|item| NxTasks::ratio(item) < 1 }
    end

    # NxTasks::tail(cardinal)
    def self.tail(cardinal)
        Items::mikuType("NxTask")
            .select{|item| item["taskType-11"]["variant"] == "tail" }
            .sort_by{|item| item["taskType-11"]["position"] }
            .reduce([]){|collection, item|
                if collection.size >= cardinal then
                    collection
                else
                    if Listing::listable(item) then
                        if Bank1::recoveredAverageHoursPerDay(item["uuid"]) < 1 and Bank1::getValueAtDate(item["uuid"], CommonUtils::today()) < 3600 then
                            collection + [item]
                        else
                            collection
                        end
                    else
                        collection
                    end
                end
            }
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

    # NxTasks::interactivelyIssueDxTaskType()
    def self.interactivelyIssueDxTaskType()
        variants = [
            "on date",
            "task with time commitment",
            "general time commitment",
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
                    "position" => NxTasks::between10And20Position()
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
                    .select{|item| NxTasks::isTimeCommitment(item) }
                    .sort_by{|item| NxTasks::ratio(item) }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", items, lambda{|item| PolyFunctions::toString(item) })
    end

    # ------------------
    # Data

    # NxTasks::issueTailCurvePoint()
    def self.issueTailCurvePoint()
        repository = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Catalyst/data/tailcurve"
        cardinal = Items::mikuType("NxTask").size
        unixtime = Time.new.to_i
        filepath = "#{CommonUtils::timeStringL22()}.json"
        filepath = "#{repository}/#{filepath}"
        point = {
            "unixtime" => unixtime,
            "cardinal" => cardinal
        }
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(point)) }
    end
end
