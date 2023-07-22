
class NxOndates

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        BladesGI::init("NxOndate", uuid)
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", datetime)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::setAttribute2(uuid, "field11", coredataref)
        BladesGI::itemOrNull(uuid)
    end

    # NxOndates::interactivelyIssueNewTodayOrNull()
    def self.interactivelyIssueNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        BladesGI::init("NxOndate", uuid)
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::setAttribute2(uuid, "field11", coredataref)
        BladesGI::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxOndates::toString(item)
    def self.toString(item)
        "🗓️  (#{item["datetime"][0, 10]}) #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # NxOndates::listingItems()
    def self.listingItems()
        BladesItemised::mikuType("NxOndate")
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

            items = BladesItemised::mikuType("NxOndate")
                        .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }

            items
                .each{|item|
                    store.register(item, Listing::canBeDefault(item))
                    puts Listing::toString2(store, item)
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
        CoreDataRefStrings::access(item["uuid"], item["field11"])
    end

    # NxOndates::redate(item)
    def self.redate(item)
        unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
        return if unixtime.nil?
        BladesGI::setAttribute2(item["uuid"], "datetime", Time.at(unixtime).utc.iso8601)
        BladesGI::setAttribute2(item["uuid"], "parking", nil)
        DoNotShowUntil::setUnixtime(item, unixtime)
    end

    # NxOndates::fsck()
    def self.fsck()
        BladesItemised::mikuType("NxOndate").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
