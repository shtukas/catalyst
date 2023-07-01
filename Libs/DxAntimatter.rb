
class DxAntimatters

    # DxAntimatters::issue(familyId, description, initialValue)
    def self.issue(familyId, description, initialValue)
        uuid = SecureRandom.uuid
        DarkEnergy::init("DxAntimatter", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "familyId", familyId)
        DarkEnergy::patch(uuid, "initialValue", initialValue)
        DarkEnergy::itemOrNull(uuid)
    end

    # DxAntimatters::value(item)
    def self.value(item)
        item["initialValue"] + Bank::getValue(item["uuid"])
    end

    # DxAntimatters::toString(item)
    def self.toString(item)
       valueInHours = DxAntimatters::value(item).to_f/3600
        "🍄 #{item["description"]} #{valueInHours.round(2)} hours"
    end

    # DxAntimatters::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("DxAntimatter")
            .select{|item|
                DxAntimatters::value(item) < 0 or DoNotShowUntil::isVisible(item)
            }
    end

    # DxAntimatters::maintenance()
    def self.maintenance()

    end
end