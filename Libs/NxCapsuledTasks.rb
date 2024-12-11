
class NxCapsuledTasks

    # NxCapsuledTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours per week: ").to_f
        payload = UxPayload::makeNewOrNull(uuid)
        Items::itemInit(uuid, "NxCapsuledTask")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "uxpayload-b4e4", payload)
        Items::setAttribute(uuid, "hoursPerWeek", hours)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxCapsuledTasks::toString(item)
    def self.toString(item)
        "🐠 #{item["description"]}"
    end

    # NxCapsuledTasks::maintenance()
    def self.maintenance()
        Items::mikuType("NxCapsuledTask").each{|item|
            if NxTimeCapsules::getCapsulesForTarget(item["uuid"]).all?{|capsule| NxTimeCapsules::liveValue(capsule) >= 0 } then
                Constellation::constellationWithTimeControl(item["uuid"], item["description"], 7, item["hoursPerWeek"], 7)
            end
        }
    end
end
