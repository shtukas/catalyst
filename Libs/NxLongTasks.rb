
class NxLongTasks

    # NxLongTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours per day: ").to_f
        payload = UxPayload::makeNewOrNull(uuid)
        Items::itemInit(uuid, "NxLongTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "hoursPerDay", hours)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxLongTasks::toString(item)
    def self.toString(item)
        "🐠 #{item["description"]}"
    end

    # NxLongTasks::maintenance()
    def self.maintenance()
        Items::mikuType("NxLongTask").each{|item|
            if NxTimeCapsules::getCapsulesForTarget(item["uuid"]).all?{|capsule| NxTimeCapsules::liveValue(capsule) >= 0 } then
                NxTimeCapsules::constellation(item["uuid"], item["description"], 7, item["hoursPerDay"]*7)
            end
        }
    end
end
