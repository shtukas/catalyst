class NxPriorities

    # NxPriorities::issueNew(description)
    def self.issueNew(description)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "mikuType", "NxPriority")
        item = Items::itemOrNull(uuid)
        item
    end

    # ----------------------
    # Data

    # NxPriorities::toString(item)
    def self.toString(item)
        "🔥 #{item["description"]}"
    end

    # NxPriorities::listingItems()
    def self.listingItems()
        Items::mikuType("NxPriority").sort_by{|item| item["unixtime"] }.reverse
    end
end
