
class NxStrats

    # NxStrats::interactivelyIssueNewOrNull(description, bottomuuid)
    def self.interactivelyIssueNewOrNull(description, bottomuuid)
        uuid = SecureRandom.uuid
        Items::itemInit(uuid, "NxStrat")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "bottomuuid", bottomuuid)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxStrats::toString(item)
    def self.toString(item)
        "✨ #{item["description"]}"
    end

    # NxStrats::pile_one(item)
    def self.pile_one(item)
        puts "pile(1) on #{PolyFunctions::toString(item).green}"
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        NxStrats::interactivelyIssueNewOrNull(description, item["uuid"])
    end

    # NxStrats::pile_plus(item)
    def self.pile_plus(item)
        puts "pile(+) on #{PolyFunctions::toString(item).green}"
        text = CommonUtils::editTextSynchronously("")
        lines = text.strip.lines.map{|line| line.strip }
        lines = lines.reverse
        cursor = item
        lines.each{|line|
            st = NxStrats::interactivelyIssueNewOrNull(line, cursor["uuid"])
            cursor = st
        }
    end

    # NxStrats::parentOrNull(item)
    def self.parentOrNull(item)
        Items::mikuType("NxStrat").select{|st| st["bottomuuid"] == item["uuid"] }.first
    end
end
