
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
        Cubes::init(nil, "PhysicalTarget", uuid)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::setAttribute2(uuid, "dailyTarget", dailyTarget)
        Cubes::setAttribute2(uuid, "date", CommonUtils::today())
        Cubes::setAttribute2(uuid, "counter", 0)
        Cubes::setAttribute2(uuid, "lastUpdatedUnixtime", lastUpdatedUnixtime)
        Cubes::itemOrNull(uuid)
    end

    # --------------------------------------------------------
    # Data

    # PhysicalTargets::toString(item)
    def self.toString(item)
        "#{item["description"]} (done: #{item["counter"]}, remaining: #{item["dailyTarget"] - item["counter"]})#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # PhysicalTargets::listingItems()
    def self.listingItems()
        Cubes::mikuType("PhysicalTarget").each{|item|
            if item["date"] != CommonUtils::today() then
                Cubes::setAttribute2(item["uuid"], "date", CommonUtils::today())
                Cubes::setAttribute2(item["uuid"], "counter", 0)
            end
        }
        Cubes::mikuType("PhysicalTarget")
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
        Cubes::setAttribute2(item["uuid"], "counter", count + item["counter"])
        Cubes::setAttribute2(item["uuid"], "lastUpdatedUnixtime", Time.new.to_i)
    end

    # PhysicalTargets::access(item)
    def self.access(item)
        PhysicalTargets::performUpdate(item)
    end
end
