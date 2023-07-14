# encoding: UTF-8

class Daily

    # Daily::todayOrNull()
    def self.todayOrNull()
        CatalystSharedCache::getOrDefaultValue("025c7410-3d6c-453e-a5e8-cc040e0255e9:#{CommonUtils::today()}", nil)
    end

    # Daily::adduuid(uuid, hours)
    def self.adduuid(uuid, hours)
        today = Daily::todayOrNull()
        if today.nil? then
            today = {}
        end
        today[uuid] = hours
        CatalystSharedCache::set("025c7410-3d6c-453e-a5e8-cc040e0255e9:#{CommonUtils::today()}", today)
    end

    # Daily::unregister(uuid)
    def self.unregister(uuid)
        today = Daily::todayOrNull()
        if today.nil? then
            today = {}
        end
        today.delete(uuid)
        CatalystSharedCache::set("025c7410-3d6c-453e-a5e8-cc040e0255e9:#{CommonUtils::today()}", today)
    end

    # Daily::toString(item)
    def self.toString(item)
        "   (daily: #{"%5.2f" % (100*item["ratio"])} % of #{"%4.2f" % item["hours"]} hours) #{PolyFunctions::toString(item["item"])}"
    end
end
