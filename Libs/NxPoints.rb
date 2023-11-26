
class NxPoints

    # NxPoints::issue(uuid, description)
    def self.issue(uuid, description)
        DataCenter::itemInit(uuid, "NxPoint")
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "field11", coredataref)
        DataCenter::itemOrNull(uuid)
    end

    # NxPoints::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        NxPoints::issue(SecureRandom.uuid, description)
    end

    # ------------------
    # Data

    # NxPoints::toString(item)
    def self.toString(item)
        "🔹 #{item["description"]}"
    end
end
