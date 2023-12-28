
class NxOndates

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        Cubes::itemInit(uuid, "NxOndate")
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        Cubes::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute(uuid, "datetime", datetime)
        Cubes::setAttribute(uuid, "description", description)
        Cubes::setAttribute(uuid, "field11", coredataref)
        CacheWS::emit("mikutype-has-been-modified:NxOndate")
        Cubes::itemOrNull(uuid)
    end

    # NxOndates::interactivelyIssueAtDatetimeNewOrNull(datetime)
    def self.interactivelyIssueAtDatetimeNewOrNull(datetime)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        Cubes::itemInit(uuid, "NxOndate")
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        Cubes::setAttribute(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute(uuid, "datetime", datetime)
        Cubes::setAttribute(uuid, "description", description)
        Cubes::setAttribute(uuid, "field11", coredataref)
        CacheWS::emit("mikutype-has-been-modified:NxOndate")
        Cubes::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxOndates::toString(item)
    def self.toString(item)
        "🗓️  #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item).red}"
    end

    # NxOndates::listingItems()
    def self.listingItems()
        Cubes::mikuType("NxOndate")
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
    end

    # NxOndates::item(item)
    def self.item(item)
        ratio = NxBlocks::dayCompletionRatio(item)
        hours = item["engine-0020"]["hours"]
        [(1-ratio), 0].max * hours * 3600
    end
end
