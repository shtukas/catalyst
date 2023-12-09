
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
        DataCenter::setAttribute(uuid, "engine", engine)
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
        DataCenter::setAttribute(uuid, "engine", engine)
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
                if !TxBoosters::hasActiveBooster(item) then
                    puts "I need a booster for #{NxOndates::toString(item).green}"
                    booster = TxBoosters::interactivelyMakeNewOrNull()
                    DataCenter::setAttribute(item["uuid"], "booster-1521", booster)
                    item["booster-1521"] = booster
                end
                item
            }
    end

    # NxOndates::item(item)
    def self.item(item)
        ratio = TxBoosters::completionRatio(item["booster-1521"])
        hours = item["booster-1521"]["hours"]
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
