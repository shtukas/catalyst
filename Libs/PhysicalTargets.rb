
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
        Items::itemInit(uuid, "PhysicalTarget")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "dailyTarget", dailyTarget)
        Items::setAttribute(uuid, "date", CommonUtils::today())
        Items::setAttribute(uuid, "counter", 0)
        Items::setAttribute(uuid, "lastUpdatedUnixtime", lastUpdatedUnixtime)

        Items::itemOrNull(uuid)
    end

    # --------------------------------------------------------
    # Data

    # PhysicalTargets::toString(item)
    def self.toString(item)
        "💪 #{item["description"]} (done: #{item["counter"]}, remaining: #{item["dailyTarget"] - item["counter"]})"
    end

    # PhysicalTargets::muiItems()
    def self.muiItems()
        Items::mikuType("PhysicalTarget").each{|item|
            if item["date"] != CommonUtils::today() then
                Items::setAttribute(item["uuid"], "date", CommonUtils::today())
                Items::setAttribute(item["uuid"], "counter", 0)
            end
        }
        Items::mikuType("PhysicalTarget")
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
        Items::setAttribute(item["uuid"], "counter", count + item["counter"])
        Items::setAttribute(item["uuid"], "lastUpdatedUnixtime", Time.new.to_i)
    end

    # PhysicalTargets::access(item)
    def self.access(item)
        PhysicalTargets::performUpdate(item)
    end
end
