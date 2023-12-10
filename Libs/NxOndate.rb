
class NxOndates

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        DataCenter::itemInit(uuid, "NxOndate")
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", datetime)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "field11", coredataReference)
        DataCenter::itemOrNull(uuid)
    end

    # NxOndates::interactivelyIssueAtDatetimeNewOrNull(datetime)
    def self.interactivelyIssueAtDatetimeNewOrNull(datetime)
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        DataCenter::itemInit(uuid, "NxOndate")
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", datetime)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::setAttribute(uuid, "field11", coredataReference)
        DataCenter::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxOndates::toString(item)
    def self.toString(item)
        "🗓️  #{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item).red}"
    end

    # NxOndates::listingItems()
    def self.listingItems()
        DataCenter::mikuType("NxOndate")
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
            .map{|item|
                if !TxCores::extractActiveBoosterOrNull(item) then
                    puts "I need a booster for #{NxOndates::toString(item).green}"
                    booster = TxCores::interactivelyMakeBoosterOrNull()
                    if booster then
                        engine = [booster] + (item["engine-0020"] || [])
                        DataCenter::setAttribute(item["uuid"], "engine-0020", engine)
                        item["engine-0020"] = engine
                    end
                end
                item
            }
    end

    # NxOndates::item(item)
    def self.item(item)
        ratio = TxCores::coreDayCompletionRatio(item["engine-0020"][0])
        hours = item["engine-0020"]["hours"]
        [(1-ratio), 0].max * hours * 3600
    end

    # NxOndates::eta()
    def self.eta()
        NxOndates::listingItems()
            .select{|item| Listing::listable(item) }
            .map{|item| NxCruisers::itemEta(item) }
            .inject(0, :+)
    end
end
