
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
        Updates::itemInit(uuid, "PhysicalTarget")
        Updates::itemAttributeUpdate(uuid, "description", description)
        Updates::itemAttributeUpdate(uuid, "dailyTarget", dailyTarget)
        Updates::itemAttributeUpdate(uuid, "date", CommonUtils::today())
        Updates::itemAttributeUpdate(uuid, "counter", 0)
        Updates::itemAttributeUpdate(uuid, "lastUpdatedUnixtime", lastUpdatedUnixtime)
        Catalyst::itemOrNull(uuid)
    end

    # --------------------------------------------------------
    # Data

    # PhysicalTargets::toString(item)
    def self.toString(item)
        "#{item["description"]} (done: #{item["counter"]}, remaining: #{item["dailyTarget"] - item["counter"]})#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # PhysicalTargets::listingItems()
    def self.listingItems()
        Catalyst::mikuType("PhysicalTarget").each{|item|
            if item["date"] != CommonUtils::today() then
                Updates::itemAttributeUpdate(item["uuid"], "date", CommonUtils::today())
                Updates::itemAttributeUpdate(item["uuid"], "counter", 0)
            end
        }
        Catalyst::mikuType("PhysicalTarget")
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
        Updates::itemAttributeUpdate(item["uuid"], "counter", count + item["counter"])
        Updates::itemAttributeUpdate(item["uuid"], "lastUpdatedUnixtime", Time.new.to_i)
    end

    # PhysicalTargets::access(item)
    def self.access(item)
        PhysicalTargets::performUpdate(item)
    end
end
