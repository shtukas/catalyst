
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

    # DxAntimatters::familySamplePositiveNonRunningOrNull(familyId)
    def self.familySamplePositiveNonRunningOrNull(familyId)
        DarkEnergy::mikuType("DxAntimatter")
            .select{|item| item["familyId"] == familyId }
            .select{|item| !NxBalls::itemIsRunning(item) }
            .select{|item| DxAntimatters::value(item) >= 0 }
            .sample
    end

    # DxAntimatters::familySampleNegativeNonRunningOrNull(familyId)
    def self.familySampleNegativeNonRunningOrNull(familyId)
        DarkEnergy::mikuType("DxAntimatter")
            .select{|item| item["familyId"] == familyId }
            .select{|item| !NxBalls::itemIsRunning(item) }
            .select{|item| DxAntimatters::value(item) < 0 }
            .sample
    end

    # DxAntimatters::maintenance()
    def self.maintenance()
        item = DarkEnergy::mikuType("DxAntimatter").sample
        return if item.nil? # there was no antimatter item at this stage
        familyId = item["familyId"]
        positive = DxAntimatters::familySamplePositiveNonRunningOrNull(familyId)
        return if positive.nil?
        negative = DxAntimatters::familySampleNegativeNonRunningOrNull(familyId)
        return if negative.nil?
        puts "DxAntimatters::maintenance()"
        puts "with:"
        puts JSON.pretty_generate(positive)
        puts "value: #{DxAntimatters::value(positive)}"
        puts "with:"
        puts JSON.pretty_generate(negative)
        combinedValue = DxAntimatters::value(positive) + DxAntimatters::value(negative)
        combinedItem = DxAntimatters::issue(familyId, positive["description"], combinedValue)
        puts "value: #{DxAntimatters::value(negative)}"
        puts "combined:"
        puts JSON.pretty_generate(combinedItem)
        LucilleCore::pressEnterToContinue()
    end
end