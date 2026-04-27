class NxTasks

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        payload = UxPayloads::makeNewPayloadOrNull()
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-37", payload)
        Items::setAttribute(uuid, "global-pos-07", GlobalPositioning::first_position - 1)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        item = Items::itemOrNull(uuid)
        item
    end

    # NxTasks::simpleTaskfromDescription(description)
    def self.simpleTaskfromDescription(description)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "global-pos-07", GlobalPositioning::first_position - 1)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        item = Items::itemOrNull(uuid)
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
        cursor = Time.new.to_i/3600
        if uuids = XCache::getOrNull("1c4e4f1a-b032-48d5-9e3c-b14c56bfc209:#{cursor}") then
            return JSON.parse(uuids).map{|uuid| Items::itemOrNull(uuid) }.compact
        end
        items = Items::mikuType("NxTask").sort_by{|item| item["global-pos-07"] }.take(30)
        XCache::set("1c4e4f1a-b032-48d5-9e3c-b14c56bfc209:#{cursor}", JSON.generate(items.map{|item| item["uuid"] }))
        items
    end
end
