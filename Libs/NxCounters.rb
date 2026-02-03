
class NxCounters

    # NxCounters::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        cursorCounter = 0
        incrementPerDay = LucilleCore::askQuestionAnswerAsString("increment per day: ").to_i
        return nil if incrementPerDay == 0
        lastUpdateUnixtime = Time.new.to_i
        doneCounter = 0
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "incrementPerDay", incrementPerDay)
        Blades::setAttribute(uuid, "mikuType", "NxCounter")
        item = Blades::itemOrNull(uuid)
        item
    end

    # NxCounters::icon(item)
    def self.icon(item)
        "🌁"
    end

    # NxCounters::getDayData(item)
    def self.getDayData(item)
        if item["dayData"] and item["dayData"]["date"] == CommonUtils::today() then
            return item["dayData"]
        end
        {
            "date" => CommonUtils::today(),
            "done" => 0,
            "lastUpdateUnixtime" => 0,
        }
    end

    # NxCounters::missingCount(item)
    def self.missingCount(item)
        item["incrementPerDay"] - NxCounters::getDayData(item)["done"]
    end

    # NxCounters::toString(item)
    def self.toString(item)
        "#{NxCounters::icon(item)} #{item["description"]} (missing: #{NxCounters::missingCount(item)})"
    end

    # NxCounters::interactivelyIncrement(item)
    def self.interactivelyIncrement(item)
        dayData = NxCounters::getDayData(item)
        increment = LucilleCore::askQuestionAnswerAsString("increment: ").to_i
        dayData["done"] = dayData["done"] + increment
        dayData["lastUpdateUnixtime"] = Time.new.to_i
        Blades::setAttribute(item["uuid"], "dayData", dayData)
    end

    # NxCounters::listingItems()
    def self.listingItems()
        Blades::mikuType("NxCounter").select{|item|
            dayData = NxCounters::getDayData(item)
            NxCounters::missingCount(item) > 0 and (Time.new.to_f - dayData["lastUpdateUnixtime"]) >= 3600
        }
    end
end
