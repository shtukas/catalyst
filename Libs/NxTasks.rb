class NxTasks

    # NxTasks::interactivelyIssueNewOrNull(parent)
    def self.interactivelyIssueNewOrNull(parent)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        payload = UxPayloads::makeNewPayloadOrNull(uuid)
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "payload-37", payload)
        Blades::setAttribute(uuid, "global-pos-07", GlobalPositioning::last_position() + 1)
        Blades::setAttribute(uuid, "px14", parent["uuid"])
        Blades::setAttribute(uuid, "mikuType", "NxTask")
        item = Blades::itemOrNull(uuid)
        item
    end

    # NxTasks::simpleTaskfromDescription(parent, description)
    def self.simpleTaskfromDescription(parent, description)
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "global-pos-07", GlobalPositioning::last_position() + 1)
        Blades::setAttribute(uuid, "px14", parent["uuid"])
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

    # NxTasks::listingItems()
    def self.listingItems()
        Blades::mikuType("NxTask").sort_by{|item| item["global-pos-07"] }.take(30)
    end
end
