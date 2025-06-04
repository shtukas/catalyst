
class NxStackPriorities

    # NxStackPriorities::interactivelyIssueNewOrNull(description)
    def self.interactivelyIssueNewOrNull(description)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "mikuType", "NxStackPriority")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "position", NxStackPriorities::getNewTopPosition())
        Items::itemOrNull(uuid)
    end

    # NxStackPriorities::toString(item)
    def self.toString(item)
        "🔺 #{item["description"]}"
    end

    # NxStackPriorities::getNewTopPosition()
    def self.getNewTopPosition()
        ([0] + Items::mikuType("NxStackPriority").map{|item| item["position"] || 0 }).min - 1
    end
end
