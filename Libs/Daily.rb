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

    # Daily::dailies()
    def self.dailies()
        Daily::todayOrNull()
            .to_a
            .map{|uuid, hours|
                item = DarkEnergy::itemOrNull(uuid)
                dayDoneInHours = Bank::getValueAtDate(uuid, CommonUtils::today()).to_f/3600
                if dayDoneInHours < hours then
                    {
                        "uuid"     => Digest::SHA1.hexdigest("Daily:aae9d799:#{CommonUtils::today()}:#{item["uuid"]}"),
                        "mikuType" => "NxDaily",
                        "hours"    => hours,
                        "ratio"    => dayDoneInHours.to_f/hours,
                        "item"     => item
                    }
                else
                    nil
                end
            }
            .compact
            .sort_by{|item| item["ratio"] }
    end

    # Daily::listingItems()
    def self.listingItems()
        Daily::dailies()
            .select{|item| Listing::listable(item["item"]) }
    end

    # Daily::dailyForTargetItemOrNull(item)
    def self.dailyForTargetItemOrNull(item)
        Daily::dailies().select{|daily| daily["item"]["uuid"] == item["uuid"] }.first
    end
end
