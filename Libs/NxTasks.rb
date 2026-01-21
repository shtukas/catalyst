

$memory1503 = nil

class NxTasks

    # NxTasks::interactivelyIssueNewOrNull(nx38 or null)
    def self.interactivelyIssueNewOrNull(nx38 = nil)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        payload = UxPayloads::makeNewPayloadOrNull(uuid)
        nx38 = nx38 || Nx38s::architectNx38()
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "payload-37", payload)
        Blades::setAttribute(uuid, "clique8", [nx38])
        Blades::setAttribute(uuid, "mikuType", "NxTask")
        item = Blades::itemOrNull(uuid)
        item
    end

    # ----------------------
    # Data

    # NxTasks::icon()
    def self.icon()
        "🔹"
    end

    # NxTasks::toString(item)
    def self.toString(item)
        "#{NxTasks::icon()} #{item["description"]}"
    end
end
