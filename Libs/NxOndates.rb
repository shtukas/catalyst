
class NxOndates

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        datetime = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxOndate", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", datetime)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxOndates::interactivelyIssueNewTodayOrNull()
    def self.interactivelyIssueNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        DarkEnergy::init("NxOndate", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxOndates::toString(item)
    def self.toString(item)
        "🗓️  (#{item["datetime"][0, 10]}) #{item["description"]}#{CoreData::itemToSuffixString(item)}#{TxCores::coreSuffix(item)}"
    end

    # NxOndates::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxOndate")
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
            .sort_by{|item| item["unixtime"] }
    end

    # ------------------
    # Ops

    # NxOndates::program()
    def self.program()
        loop {
            system("clear")
            
            store = ItemStore.new()

            items = DarkEnergy::mikuType("NxOndate")
                        .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }

            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts Listing::toString(store, item)
                }

            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""
            return if input == "exit"
            puts ""
            ListingCommandsAndInterpreters::interpreter(input, store)
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
        DarkEnergy::patch(item["uuid"], "datetime", Time.at(unixtime).utc.iso8601)
        DarkEnergy::patch(item["uuid"], "parking", nil)
        DoNotShowUntil::setUnixtime(item, unixtime)
    end
end
