
class Environments

    # Environments::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        hours = LucilleCore::askQuestionAnswerAsString("commitment per week in hours: ").to_f
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "tc-16", hours)
        Blades::setAttribute(uuid, "mikuType", "Environment")
        item = Blades::itemOrNull(uuid)
        item
    end

    # Environments::icon()
    def self.icon()
        "⛵️"
    end

    # Environments::toString(item)
    def self.toString(item)
        "#{Environments::icon()} #{item["description"]}"
    end
end
