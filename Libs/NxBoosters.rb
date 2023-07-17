# encoding: UTF-8

class NxBoosters

    # NxBoosters::issue(description, hours)
    def self.issue(description, hours)
        uuid = SecureRandom.uuid
        Blades::init("NxBooster", uuid)
        Blades::setAttribute2(uuid, "date", CommonUtils::today())
        Blades::setAttribute2(uuid, "description", description)
        Blades::setAttribute2(uuid, "hours", hours)
    end

    # NxBoosters::toString(item)
    def self.toString(item)
        "🚀 (#{"%6.2f" % (100*NxBoosters::ratio(item["uuid"]))} % of #{"%4.2f" % item["hours"]} hours) #{item["description"]}"
    end

    # NxBoosters::ratio(uuid)
    def self.ratio(uuid)
        dayDoneInHours = Bank::getValue(uuid).to_f/3600
        hours = Blades::getAttributeOrNull2(uuid, "hours")
        dayDoneInHours.to_f/hours
    end

    # NxBoosters::listingItems()
    def self.listingItems()
        Solingen::mikuTypeUUIDs("NxBooster")
            .sort_by{|uuid| NxBoosters::ratio(uuid) }
            .map{|uuid|
                date = Blades::getAttributeOrNull2(uuid, "date")
                description = Blades::getAttributeOrNull2(uuid, "description")
                hours = Blades::getAttributeOrNull2(uuid, "hours")
                {
                    "uuid"        => uuid,
                    "mikuType"    => "NxBooster",
                    "date"        => date,
                    "hours"       => hours,
                    "description" => description,
                }
            }
    end
end
