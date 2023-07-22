
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
        BladesGI::init("PhysicalTarget", uuid)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::setAttribute2(uuid, "dailyTarget", dailyTarget)
        BladesGI::setAttribute2(uuid, "date", CommonUtils::today())
        BladesGI::setAttribute2(uuid, "counter", 0)
        BladesGI::setAttribute2(uuid, "lastUpdatedUnixtime", lastUpdatedUnixtime)
        BladesGI::itemOrNull(uuid)
    end

    # --------------------------------------------------------
    # Data

    # PhysicalTargets::toString(item)
    def self.toString(item)
        "#{item["description"]} (done: #{item["counter"]}, remaining: #{item["dailyTarget"] - item["counter"]})#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # PhysicalTargets::listingItems()
    def self.listingItems()
        BladesItemised::mikuType("PhysicalTarget").each{|item|
            if item["date"] != CommonUtils::today() then
                BladesGI::setAttribute2(item["uuid"], "date", CommonUtils::today())
                BladesGI::setAttribute2(item["uuid"], "counter", 0)
            end
        }
        BladesItemised::mikuType("PhysicalTarget")
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
        BladesGI::setAttribute2(item["uuid"], "counter", count + item["counter"])
        BladesGI::setAttribute2(item["uuid"], "lastUpdatedUnixtime", Time.new.to_i)
    end

    # PhysicalTargets::access(item)
    def self.access(item)
        PhysicalTargets::performUpdate(item)
    end
end
