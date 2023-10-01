
class NxBurners

    # NxBurners::issue(description)
    def self.issue(description)
        uuid = SecureRandom.uuid
        Events::publishItemInit("NxBurner", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Catalyst::itemOrNull(uuid)
    end

    # NxBurners::toString(item)
    def self.toString(item)
        "🔥 #{item["description"]}#{TxCores::suffix(item)}"
    end

    # NxBurners::listingItems()
    def self.listingItems()
        Catalyst::mikuType("NxBurner").sort_by{|item| item["unixtime"] }
    end
end