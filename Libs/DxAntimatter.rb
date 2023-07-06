
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
            #.select{|item|
            #    DxAntimatters::value(item) < 0 or NxBalls::itemIsActive(item)
            #}
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

    # DxAntimatters::familyIds()
    def self.familyIds()
        DarkEnergy::mikuType("DxAntimatter")
            .map{|item| item["familyId"] }
            .uniq
    end

    # DxAntimatters::familyMaintenance(familyId)
    def self.familyMaintenance(familyId)
        loop {
            positive = DxAntimatters::familySamplePositiveNonRunningOrNull(familyId)
            break if positive.nil?
            negative = DxAntimatters::familySampleNegativeNonRunningOrNull(familyId)
            break if negative.nil?

            puts "DxAntimatters::maintenance()"
            puts "with:"
            puts JSON.pretty_generate(positive)
            puts "value: #{DxAntimatters::value(positive)}"

            puts "with:"
            puts JSON.pretty_generate(negative)
            puts "value: #{DxAntimatters::value(negative)}"

            combinedValue = DxAntimatters::value(positive) + DxAntimatters::value(negative)
            combinedItem = DxAntimatters::issue(familyId, positive["description"], combinedValue)
            puts "combined:"
            puts JSON.pretty_generate(combinedItem)

            DarkEnergy::destroy(positive["uuid"])
            DarkEnergy::destroy(negative["uuid"])

            ListingPositions::set(combinedItem, ListingPositions::randomPositionInLateRange())
        }
    end

    # DxAntimatters::maintenance()
    def self.maintenance()
        DxAntimatters::familyIds().each{|familyId|
            DxAntimatters::familyMaintenance(familyId)
        }
    end
end