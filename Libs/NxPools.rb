
class NxPools

    # NxPools::issue(uuids, dailyHours, weeklyHours)
    def self.issue(uuids, dailyHours, weeklyHours)
        description = line
        uuid = SecureRandom.uuid
        Cubes::init(nil, "NxPool", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "uuids", uuids)
        Cubes::setAttribute2(uuid, "dailyHours", dailyHours)
        Cubes::setAttribute2(uuid, "weeklyHours", weeklyHours)
        Cubes::itemOrNull(uuid)
    end

    # NxPools::poolToElementsInOrder(pool)
    def self.poolToElementsInOrder(pool)
        []
    end

    # NxPools::listingItems()
    def self.listingItems()
        []
    end
end
