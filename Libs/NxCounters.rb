
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
        Blades::setAttribute(uuid, "cursorCounter", cursorCounter)
        Blades::setAttribute(uuid, "incrementPerDay", incrementPerDay)
        Blades::setAttribute(uuid, "lastUpdateUnixtime", lastUpdateUnixtime)
        Blades::setAttribute(uuid, "doneCounter", doneCounter)
        Blades::setAttribute(uuid, "mikuType", "NxCounter")
        item = Blades::itemOrNull(uuid)
        item
    end

    # NxCounters::icon(item)
    def self.icon(item)
        "🌁"
    end

    # NxCounters::toString(item)
    def self.toString(item)
        if Time.new.to_i - item["lastUpdateUnixtime"] > 3600 then
            deltaTimeInDays = (Time.new.to_i - item["lastUpdateUnixtime"]).to_f/86400
            deltaIncrement = [deltaTimeInDays * item["incrementPerDay"], item["incrementPerDay"]].min
            cursorCounter = item["cursorCounter"] + deltaIncrement
            Blades::setAttribute(item["uuid"], "cursorCounter", cursorCounter)
            Blades::setAttribute(item["uuid"], "lastUpdateUnixtime", Time.new.to_i)
            item = Blades::itemOrNull(item["uuid"])
        end
        missing = item["cursorCounter"] - item["doneCounter"]
        "#{NxCounters::icon(item)} #{item["description"]} (missing: #{missing})"
    end

    # NxCounters::interactivelyIncrement(item)
    def self.interactivelyIncrement(item)
        increment = LucilleCore::askQuestionAnswerAsString("increment: ").to_i
        doneCounter = item["doneCounter"] + increment
        Blades::setAttribute(item["uuid"], "doneCounter", doneCounter)
    end

    # NxCounters::listingItems()
    def self.listingItems()
        Blades::mikuType("NxCounter").select{|item|
            missing = item["cursorCounter"] - item["doneCounter"]
            missing > -item["incrementPerDay"].to_f/5
        }
    end
end
