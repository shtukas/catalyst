
class NxOndates

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        Cubes1::itemInit(uuid, "NxOndate")
        payload = TxPayload::interactivelyMakeNew(uuid)
        payload.each{|k, v| Cubes1::setAttribute(uuid, k, v) }
        Cubes1::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes1::setAttribute(uuid, "datetime", datetime)
        Cubes1::setAttribute(uuid, "description", description)
        Cubes1::itemOrNull(nil, uuid)
    end

    # NxOndates::interactivelyIssueAtDatetimeNewOrNull(datetime)
    def self.interactivelyIssueAtDatetimeNewOrNull(datetime)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Cubes1::itemInit(uuid, "NxOndate")
        payload = TxPayload::interactivelyMakeNew(uuid)
        payload.each{|k, v| Cubes1::setAttribute(uuid, k, v) }
        Cubes1::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes1::setAttribute(uuid, "datetime", datetime)
        Cubes1::setAttribute(uuid, "description", description)
        Cubes1::itemOrNull(nil, uuid)
    end

    # ------------------
    # Data

    # NxOndates::toString(item)
    def self.toString(item)
        "🗓️  #{item["description"]}"
    end

    # NxOndates::muiItems(datatrace)
    def self.muiItems(datatrace)
        Cubes1::mikuType(datatrace, "NxOndate")
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
            .sort_by{|item| item["unixtime"] }
    end
end
