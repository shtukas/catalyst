
class NxBurners

    # NxBurners::issue(description)
    def self.issue(description)
        uuid = SecureRandom.uuid
        Cubes::init(nil, "NxBurner", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::itemOrNull(uuid)
    end

    # NxBurners::toString(item)
    def self.toString(item)
        "🔥 #{item["description"]}"
    end

    # NxBurners::listingItems()
    def self.listingItems()
        Cubes::mikuType("NxBurner").sort_by{|item| item["unixtime"] }
    end
end