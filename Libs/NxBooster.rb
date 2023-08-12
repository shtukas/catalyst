
class NxBoosters

    # NxBoosters::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        deadline = nil
        loop {
            break if deadline
            deadline = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
        }
        rt = LucilleCore::askQuestionAnswerAsString("rt: ").to_f
        BladesGI::init("NxBooster", uuid)
        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::setAttribute2(uuid, "deadline", deadline)
        BladesGI::setAttribute2(uuid, "rt", rt)
        BladesGI::itemOrNull(uuid)
    end

    # NxBoosters::toString(item)
    def self.toString(item)
        ratio = Bank::recoveredAverageHoursPerDay(item["uuid"]).to_f/item["rt"]
        "🔥 #{item["description"]} (#{(100*ratio).round(2)} % of #{item["rt"]} hours)"
    end

    # NxBoosters::maintenance()
    def self.maintenance()
        BladesGI::mikuType("NxBooster").each{|item|
            next if NxBalls::itemIsActive(item)
            next if Time.new.to_f < item["deadline"]
            BladesGI::destroy(item["uuid"])
        }
    end
end