
class NxFloats

    # NxFloats::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Cubes1::itemInit(uuid, "NxFloat")
        Cubes1::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes1::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes1::setAttribute(uuid, "description", description)
        Cubes1::itemOrNull(nil, uuid)
    end

    # ------------------
    # Data

    # NxFloats::toString(item)
    def self.toString(item)
        "🐠 #{item["description"]}"
    end

    # NxFloats::muiItems(datatrace)
    def self.muiItems(datatrace)
        Cubes1::mikuType(datatrace, "NxFloat")
            .sort_by{|item| item["unixtime"] }
    end
end
