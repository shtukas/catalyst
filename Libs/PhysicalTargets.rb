
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
        Cubes2::itemInit(uuid, "PhysicalTarget")
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::setAttribute(uuid, "dailyTarget", dailyTarget)
        Cubes2::setAttribute(uuid, "date", CommonUtils::today())
        Cubes2::setAttribute(uuid, "counter", 0)
        Cubes2::setAttribute(uuid, "lastUpdatedUnixtime", lastUpdatedUnixtime)

        Cubes2::itemOrNull(uuid)
    end

    # --------------------------------------------------------
    # Data

    # PhysicalTargets::toString(item)
    def self.toString(item)
        "💪 #{item["description"]} (done: #{item["counter"]}, remaining: #{item["dailyTarget"] - item["counter"]})"
    end

    # PhysicalTargets::listingItems()
    def self.listingItems()
        Cubes2::mikuType("PhysicalTarget").each{|item|
            if item["date"] != CommonUtils::today() then
                Cubes2::setAttribute(item["uuid"], "date", CommonUtils::today())
                Cubes2::setAttribute(item["uuid"], "counter", 0)
            end
        }
        Cubes2::mikuType("PhysicalTarget")
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
        Cubes2::setAttribute(item["uuid"], "counter", count + item["counter"])
        Cubes2::setAttribute(item["uuid"], "lastUpdatedUnixtime", Time.new.to_i)
    end

    # PhysicalTargets::access(item)
    def self.access(item)
        PhysicalTargets::performUpdate(item)
    end
end
