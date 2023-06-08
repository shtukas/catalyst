
class NxOndates

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        datetime = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Solingen::init("NxOndate", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", datetime)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::getItemOrNull(uuid)
    end

    # NxOndates::interactivelyIssueNewTodayOrNull()
    def self.interactivelyIssueNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        Solingen::init("NxOndate", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::getItemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxOndates::toString(item)
    def self.toString(item)
        "🗓️  (#{item["datetime"][0, 10]}) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # NxOndates::listingItems()
    def self.listingItems()
        Solingen::mikuTypeItems("NxOndate")
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
            .sort_by{|item| item["unixtime"] }
    end

    # ------------------
    # Ops

    # NxOndates::program()
    def self.program()
        loop {
            items = Solingen::mikuTypeItems("NxOndate")
                        .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            store = ItemStore.new()

            Listing::printEvalItems(store, items)

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""
            return if input == "exit"

            ListingCommandsAndInterpreters::interpreter(input, store, nil)
        }
    end

    # NxOndates::access(item)
    def self.access(item)
        CoreData::access(item["uuid"], item["field11"])
    end

    # NxOndates::redate(item)
    def self.redate(item)
        unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
        return if unixtime.nil?
        Solingen::setAttribute2(item["uuid"], "datetime", Time.at(unixtime).utc.iso8601)
        Solingen::setAttribute2(item["uuid"], "parking", nil)
        DoNotShowUntil::setUnixtime(item, unixtime)
    end
end
