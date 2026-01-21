
class Floats

    # Floats::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull(uuid))
        Blades::setAttribute(uuid, "mikuType", "Float")
        item = Blades::itemOrNull(uuid)
        item
    end

    # Floats::icon(item)
    def self.icon(item)
        "🪸"
    end

    # Floats::toString(item)
    def self.toString(item)
        "#{Floats::icon(item)} #{item["description"]}"
    end

    # Floats::listingItems()
    def self.listingItems()
        Blades::mikuType("Float")

    end
end
