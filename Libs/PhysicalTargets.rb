
# encoding: UTF-8

class PhysicalTargets

    # PhysicalTargets::items()
    def self.items()
        BladeAdaptation::mikuTypeItems("PhysicalTarget")
    end

    # PhysicalTargets::issueNewOrNull()
    def self.issueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        dailyTarget = LucilleCore::askQuestionAnswerAsString("daily target (empty to abort): ")
        return nil if dailyTarget == ""
        dailyTarget = dailyTarget.to_i
        uuid = SecureRandom.uuid
        Blades::init("PhysicalTarget", uuid)
        Blades::setAttribute2(uuid, "description", description)
        Blades::setAttribute2(uuid, "dailyTarget", dailyTarget)
        Blades::setAttribute2(uuid, "date", CommonUtils::today())
        Blades::setAttribute2(uuid, "counter", 0)
        Blades::setAttribute2(uuid, "lastUpdatedUnixtime", lastUpdatedUnixtime)
        BladeAdaptation::getItemOrNull(uuid)
    end

    # --------------------------------------------------------
    # Data

    # PhysicalTargets::toString(item)
    def self.toString(item)
        "#{item["description"]} (done: #{item["counter"]}, remaining: #{item["dailyTarget"] - item["counter"]})"
    end

    # PhysicalTargets::listingItems()
    def self.listingItems()
        PhysicalTargets::items().each{|item|
            if item["date"] != CommonUtils::today() then
                Blades::setAttribute2(item["uuid"], "date", CommonUtils::today())
                Blades::setAttribute2(item["uuid"], "counter", 0)
            end
        }
        PhysicalTargets::items()
            .select{|item| item["counter"] < item["dailyTarget"]}
            .select{|item| item["lastUpdatedUnixtime"].nil? or (Time.new.to_i - item["lastUpdatedUnixtime"]) > 3600 }
    end

    # --------------------------------------------------------
    # Ops

    # PhysicalTargets::performUpdate(item)
    def self.performUpdate(item)
        puts "> #{item["description"]}"
        count = LucilleCore::askQuestionAnswerAsString("#{item["description"]}: done count: ").to_i
        Blades::setAttribute2(item["uuid"], "counter", counter)
        Blades::setAttribute2(item["uuid"], "lastUpdatedUnixtime", Time.new.to_i)
    end

    # PhysicalTargets::access(item)
    def self.access(item)
        PhysicalTargets::performUpdate(item)
    end
end
