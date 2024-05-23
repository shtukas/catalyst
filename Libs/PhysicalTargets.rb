
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
        Cubes1::itemInit(uuid, "PhysicalTarget")
        Cubes1::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes1::setAttribute(uuid, "description", description)
        Cubes1::setAttribute(uuid, "dailyTarget", dailyTarget)
        Cubes1::setAttribute(uuid, "date", CommonUtils::today())
        Cubes1::setAttribute(uuid, "counter", 0)
        Cubes1::setAttribute(uuid, "lastUpdatedUnixtime", lastUpdatedUnixtime)

        Cubes1::itemOrNull(uuid)
    end

    # --------------------------------------------------------
    # Data

    # PhysicalTargets::toString(item)
    def self.toString(item)
        "💪 #{item["description"]} (done: #{item["counter"]}, remaining: #{item["dailyTarget"] - item["counter"]})"
    end

    # PhysicalTargets::muiItems()
    def self.muiItems()
        Cubes1::mikuType("PhysicalTarget").each{|item|
            if item["date"] != CommonUtils::today() then
                Cubes1::setAttribute(item["uuid"], "date", CommonUtils::today())
                Cubes1::setAttribute(item["uuid"], "counter", 0)
            end
        }
        Cubes1::mikuType("PhysicalTarget")
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
        Cubes1::setAttribute(item["uuid"], "counter", count + item["counter"])
        Cubes1::setAttribute(item["uuid"], "lastUpdatedUnixtime", Time.new.to_i)
    end

    # PhysicalTargets::access(item)
    def self.access(item)
        PhysicalTargets::performUpdate(item)
    end
end
