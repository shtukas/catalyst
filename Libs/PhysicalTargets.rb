
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
        DataCenter::itemInit(uuid, "PhysicalTarget")
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "dailyTarget", dailyTarget)
        DataCenter::setAttribute(uuid, "date", CommonUtils::today())
        DataCenter::setAttribute(uuid, "counter", 0)
        DataCenter::setAttribute(uuid, "lastUpdatedUnixtime", lastUpdatedUnixtime)

        DataCenter::itemOrNull(uuid)
    end

    # --------------------------------------------------------
    # Data

    # PhysicalTargets::toString(item)
    def self.toString(item)
        "💪 #{item["description"]} (done: #{item["counter"]}, remaining: #{item["dailyTarget"] - item["counter"]})#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # PhysicalTargets::listingItems()
    def self.listingItems()
        DataCenter::mikuType("PhysicalTarget").each{|item|
            if item["date"] != CommonUtils::today() then
                DataCenter::setAttribute(item["uuid"], "date", CommonUtils::today())
                DataCenter::setAttribute(item["uuid"], "counter", 0)
            end
        }
        DataCenter::mikuType("PhysicalTarget")
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
        DataCenter::setAttribute(item["uuid"], "counter", count + item["counter"])
        DataCenter::setAttribute(item["uuid"], "lastUpdatedUnixtime", Time.new.to_i)
    end

    # PhysicalTargets::access(item)
    def self.access(item)
        PhysicalTargets::performUpdate(item)
    end
end
