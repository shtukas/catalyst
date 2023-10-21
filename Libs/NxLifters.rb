
class NxLifters

    # NxLifters::issue(targetuuid, hours)
    def self.issue(targetuuid, hours)
        uuid = SecureRandom.uuid
        Updates::itemInit(uuid, "NxLifter")
        Updates::itemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Updates::itemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Updates::itemAttributeUpdate(uuid, "targetuuid", targetuuid)
        Updates::itemAttributeUpdate(uuid, "hours", hours)
        Broadcasts::publishItem(uuid)
        Catalyst::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxLifters::toString(item)
    def self.toString(item)
        target = Catalyst::itemOrNull(item["targetuuid"])
        ts = target ? PolyFunctions::toString(target) : "(target not found)"
        done = Bank::getValueAtDate(item["uuid"], CommonUtils::today())
        "⏱️ #{"%6.2f" % (done.to_f/(item["hours"]*3600))} % of #{item["hours"]} of #{ts}"
    end

    # NxLifters::listingItems()
    def self.listingItems()
        Catalyst::mikuType("NxLifter")
            .map{|item|
                if !NxBalls::itemIsActive(item) and Bank::getValueAtDate(item["uuid"], CommonUtils::today()) >= (item["hours"]*3600) then
                    Catalyst::destroy(item["uuid"])
                    nil
                else
                    item
                end
            }
            .compact
    end
end
