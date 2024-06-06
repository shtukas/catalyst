
class NxOndates

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        Cubes1::itemInit(uuid, "NxOndate")
        Cubes1::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes1::setAttribute(uuid, "datetime", datetime)
        Cubes1::setAttribute(uuid, "description", description)
        Cubes1::setAttribute(uuid, "uxpayload-b4e4", UxPayload::makeNewOrNull())
        Cubes1::itemOrNull(uuid)
    end

    # NxOndates::interactivelyIssueAtDatetimeNewOrNull(datetime)
    def self.interactivelyIssueAtDatetimeNewOrNull(datetime)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Cubes1::itemInit(uuid, "NxOndate")
        Cubes1::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes1::setAttribute(uuid, "datetime", datetime)
        Cubes1::setAttribute(uuid, "description", description)
        Cubes1::setAttribute(uuid, "uxpayload-b4e4", UxPayload::makeNewOrNull())
        Cubes1::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxOndates::toString(item)
    def self.toString(item)
        "🗓️  #{item["description"]}"
    end

    # NxOndates::muiItems()
    def self.muiItems()
        Cubes1::mikuType("NxOndate")
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
            .sort_by{|item| item["unixtime"] }
    end
end
