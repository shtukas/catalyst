
class NxFloats

    # NxFloats::issue(line)
    def self.issue(line)
        description = line
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxFloat", uuid)
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxFloats::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxFloats::issue(description)
    end

    # NxFloats::toString(item)
    def self.toString(item)
        "🛸 #{item["description"]}"
    end
end