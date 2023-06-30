
class DxAntimatters

    # DxAntimatters::issue(familyId, description, charge)
    def self.issue(familyId, description, charge)
        uuid = SecureRandom.uuid
        DarkEnergy::init("DxAntimatter", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "familyId", familyId)
        DarkEnergy::patch(uuid, "charge", charge)
        DarkEnergy::itemOrNull(uuid)
    end

    # DxAntimatters::toString(item)
    def self.toString(item)
        "🍄 #{item["description"]} #{(item["charge"].to_f/3600).round(2)} hours"
    end
end