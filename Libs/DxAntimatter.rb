
class DxAntimatters

    # DxAntimatters::issue(targetuuid, needs)
    def self.issue(targetuuid, needs)
        uuid = SecureRandom.uuid
        DarkEnergy::init("DxAntimatter", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "targetuuid", targetuuid)
        DarkEnergy::patch(uuid, "needs", needs)
        DarkEnergy::itemOrNull(uuid)
    end

    # DxAntimatters::value(item)
    def self.value(item)
        Bank::getValue(item["uuid"]) - item["needs"]
    end

    # DxAntimatters::toString(item)
    def self.toString(item)
        target = DarkEnergy::itemOrNull(item["targetuuid"])
        valueInHours = DxAntimatters::value(item).to_f/3600
        "🔺 #{target ? "(target:) #{PolyFunctions::toString(target)}" : "(no target found)"} (needs: #{-valueInHours.round(2)} hours)"
    end

    # DxAntimatters::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("DxAntimatter")
            .select{|item| DxAntimatters::value(item) < 0 or NxBalls::itemIsActive(item)}
    end

    # DxAntimatters::maintenance()
    def self.maintenance()
        DarkEnergy::mikuType("DxAntimatter")
            .each{|item|
                target = DarkEnergy::itemOrNull(item["targetuuid"])
                if target.nil? then
                    DarkEnergy::destroy(item["uuid"])
                    next
                end
                next if NxBalls::itemIsActive(item)
                if Bank::getValue(item["uuid"]) - item["needs"] >= 0 then
                    DarkEnergy::destroy(item["uuid"])
                end
            }
    end
end