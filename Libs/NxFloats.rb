
class NxFloats

    # NxFloats::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Cubes2::itemInit(uuid, "NxFloat")
        Cubes2::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes2::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Cubes2::setAttribute(uuid, "description", description)
        Cubes2::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxFloats::toString(item)
    def self.toString(item)
        "🐠 #{item["description"]}"
    end

    # NxFloats::muiItems()
    def self.muiItems()
        Cubes2::mikuType("NxFloat")
            .sort_by{|item| item["unixtime"] }
    end
end
