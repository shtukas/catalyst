
# encoding: UTF-8

class TxNumberTargets

    # TxNumberTargets::items()
    def self.items()
        N3Objects::getMikuType("TxNumberTarget")
    end

    # TxNumberTargets::issueNewOrNull()
    def self.issueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        dailyTarget = LucilleCore::askQuestionAnswerAsString("daily target (empty to abort): ")
        return nil if dailyTarget == ""
        dailyTarget = dailyTarget.to_i
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "TxNumberTarget",
            "description" => description,
            "dailyTarget" => dailyTarget,
            "date"        => CommonUtils::today(),
            "counter"     => dailyTarget,
            "lastUpdatedUnixtime" => nil
        }
        N3Objects::commit(item)
        item
    end

    # TxNumberTargets::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # Data

    # TxNumberTargets::listingItems()
    def self.listingItems()
        TxNumberTargets::items().each{|item|
            if item["date"] != CommonUtils::today() then
                item["date"] = CommonUtils::today()
                item["counter"] = 0
                N3Objects::commit(item)
            end
        }
        TxNumberTargets::items()
            .select{|item| item["counter"] < item["dailyTarget"]}
            .select{|item| item["lastUpdatedUnixtime"].nil? or (Time.new.to_i - item["lastUpdatedUnixtime"]) > 3600 }
    end

    # Ops

    # TxNumberTargets::performUpdate(item)
    def self.performUpdate(item)
        puts "> #{item["description"]}"
        count = LucilleCore::askQuestionAnswerAsString("#{item["description"]}: done count: ").to_i
        item["counter"] = item["counter"] + count
        item["lastUpdatedUnixtime"] = Time.new.to_i
        puts JSON.pretty_generate(item)
        TxNumberTargets::commit(item)
    end

    # TxNumberTargets::access(item)
    def self.access(item)
        TxNumberTargets::performUpdate(item)
    end
end
