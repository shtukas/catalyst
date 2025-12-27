
class NxTodays

    # NxTodays::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        BladesFront::setAttribute(uuid, "unixtime", Time.new.to_i)
        BladesFront::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        BladesFront::setAttribute(uuid, "description", description)
        BladesFront::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull(uuid))
        BladesFront::setAttribute(uuid, "mikuType", "NxToday")
        item = Blades::itemOrNull(uuid)
        item
    end

    # NxTodays::icon()
    def self.icon()
        "☀️ "
    end

    # NxTodays::toString(item)
    def self.toString(item)
        "#{NxTodays::icon()} #{item["description"]}#{Parenting::suffix(item)}"
    end
end
