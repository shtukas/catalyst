
class NxProjects

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("hours per day: ").to_f
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull(uuid))
        Blades::setAttribute(uuid, "tc-15", hours)
        Blades::setAttribute(uuid, "mikuType", "NxProject")
        item = Blades::itemOrNull(uuid)
        item
    end

    # NxProjects::icon()
    def self.icon()
        "🐠"
    end

    # NxProjects::toString(item)
    def self.toString(item)
        suffix = " (#{item["tc-15"]} hours day)".yellow
        "#{NxProjects::icon()} #{item["description"]}#{suffix}"
    end
end
