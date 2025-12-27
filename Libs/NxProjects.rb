
class NxProjects

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull(uuid))
        Blades::setAttribute(uuid, "mikuType", "NxTask")
        item = Blades::itemOrNull(uuid)
        item
    end

    # NxProjects::icon()
    def self.icon()
        "⛵️"
    end

    # NxProjects::toString(item)
    def self.toString(item)
        "#{NxProjects::icon()} #{item["description"]}"
    end
end
