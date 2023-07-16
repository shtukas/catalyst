# encoding: UTF-8

class NxBoosters

    # NxBoosters::issue(item, hours)
    def self.issue(item, hours)
        uuid = SecureRandom.uuid
        Blades::init("NxBooster", uuid)
        Blades::setAttribute2(uuid, "date", CommonUtils::today())
        Blades::setAttribute2(uuid, "item", item)
        Blades::setAttribute2(uuid, "hours", hours)
    end

    # NxBoosters::toString(item)
    def self.toString(item)
        "   (booster: #{"%5.2f" % (100*item["ratio"])} % of #{"%4.2f" % item["hours"]} hours) #{PolyFunctions::toString(item["item"])}"
    end

    # NxBoosters::listingItems()
    def self.listingItems()
        Solingen::mikuTypeUUIDs("NxBooster")
            .map{|uuid|
                date  = Blades::getAttributeOrNull2(uuid, "date")
                item  = Blades::getAttributeOrNull2(uuid, "item")
                hours = Blades::getAttributeOrNull2(uuid, "hours")
                dayDoneInHours = Bank::getValueAtDate(uuid, CommonUtils::today()).to_f/3600
                if (date == CommonUtils::today()) and (dayDoneInHours < hours) then
                    {
                        "uuid"     => uuid,
                        "mikuType" => "NxBoosterX",
                        "date"     => date,
                        "hours"    => hours,
                        "item"     => item,
                        "ratio"    => dayDoneInHours.to_f/hours,
                    }
                else
                    nil
                end
            }
            .compact
            .sort_by{|item| item["ratio"] }
    end

    # NxBoosters::maintenance()
    def self.maintenance()
        Solingen::mikuTypeUUIDs("NxBooster").each{|uuid|
            date = Blades::getAttributeOrNull2(uuid, "date")
            if date != CommonUtils::today() then
                Blades::destroy(uuid)
                next
            end
            hours = Blades::getAttributeOrNull2(uuid, "hours")
            if hours.nil? then
                Blades::destroy(uuid)
                next
            end
            if Bank::getValueAtDate(uuid, CommonUtils::today()).to_f/3600 >= hours then
                Blades::destroy(uuid)
            end
        }
    end

    # NxBoosters::dailyForTargetItemOrNull(item)
    def self.dailyForTargetItemOrNull(item)
        NxBoosters::listingItems().select{|daily| daily["item"]["uuid"] == item["uuid"] }.first
    end
end
