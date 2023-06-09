
# encoding: UTF-8

class PhysicalTargets

    # PhysicalTargets::issueNewOrNull()
    def self.issueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        dailyTarget = LucilleCore::askQuestionAnswerAsString("daily target (empty to abort): ")
        return nil if dailyTarget == ""
        dailyTarget = dailyTarget.to_i
        uuid = SecureRandom.uuid
        DarkEnergy::init("PhysicalTarget", uuid)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "dailyTarget", dailyTarget)
        DarkEnergy::patch(uuid, "date", CommonUtils::today())
        DarkEnergy::patch(uuid, "counter", 0)
        DarkEnergy::patch(uuid, "lastUpdatedUnixtime", lastUpdatedUnixtime)
        DarkEnergy::itemOrNull(uuid)
    end

    # --------------------------------------------------------
    # Data

    # PhysicalTargets::toString(item)
    def self.toString(item)
        "#{item["description"]} (done: #{item["counter"]}, remaining: #{item["dailyTarget"] - item["counter"]})"
    end

    # PhysicalTargets::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("PhysicalTarget").each{|item|
            if item["date"] != CommonUtils::today() then
                DarkEnergy::patch(item["uuid"], "date", CommonUtils::today())
                DarkEnergy::patch(item["uuid"], "counter", 0)
            end
        }
        DarkEnergy::mikuType("PhysicalTarget")
            .select{|item| item["counter"] < item["dailyTarget"]}
            .select{|item| item["lastUpdatedUnixtime"].nil? or (Time.new.to_i - item["lastUpdatedUnixtime"]) > 3600 }
            .map{|item|
                item["interruption"] = true
                item
            }
    end

    # --------------------------------------------------------
    # Ops

    # PhysicalTargets::performUpdate(item)
    def self.performUpdate(item)
        puts "> #{item["description"]}"
        count = LucilleCore::askQuestionAnswerAsString("#{item["description"]}: done count: ").to_i
        DarkEnergy::patch(item["uuid"], "counter", count + DarkEnergy::read(item["uuid"], "counter"))
        DarkEnergy::patch(item["uuid"], "lastUpdatedUnixtime", Time.new.to_i)
    end

    # PhysicalTargets::access(item)
    def self.access(item)
        PhysicalTargets::performUpdate(item)
    end
end
