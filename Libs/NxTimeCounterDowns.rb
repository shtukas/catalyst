class NxTimeCounterDowns

    # NxTimeCounterDowns::issue(targetuuid, timespan, ordinal)
    def self.issue(targetuuid, timespan, ordinal)
        uuid = SecureRandom.uuid
        Cubes::init(nil, "NxTimeCounterDown", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "targetuuid", targetuuid)
        Cubes::setAttribute2(uuid, "timespan", timespan)
        Cubes::setAttribute2(uuid, "ordinal-1324", ordinal)
        Cubes::itemOrNull(uuid)
    end

    # NxTimeCounterDowns::toString(item)
    def self.toString(item)
        target = Cubes::itemOrNull(item["targetuuid"])
        str = target ? PolyFunctions::toString(target) : "(NxTimeCounterDown target not found)"

        v1 = Bank::getValue(item["uuid"])
        v2 = item["timespan"]

        "(#{100 * (v1.to_f/v2).round(2)}% of #{(item["timespan"].to_f/3600).round(2)} hours) #{str}"
    end

    # NxTimeCounterDowns::listingItems()
    def self.listingItems()
        Cubes::mikuType("NxTimeCounterDown")
            .each{|item|
                if (Bank::getValue(item["uuid"]) > item["timespan"]) and !NxBalls::itemIsActive(item) then
                    Cubes::destroy(item["uuid"])
                end
            }
        Cubes::mikuType("NxTimeCounterDown")
    end

    # NxTimeCounterDowns::getNTCDByTargetUUIDOrNull(targetuuid)
    def self.getNTCDByTargetUUIDOrNull(targetuuid)
        Cubes::mikuType("NxTimeCounterDown")
            .select{|item| item["targetuuid"] == targetuuid }
            .first
    end
end
