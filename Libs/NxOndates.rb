
class NxOndates

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        datetime = CommonUtils::interactivelyMakeDateTimeIso8601UsingDateCode()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Updates::itemInit(uuid, "NxOndate")
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        Updates::itemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Updates::itemAttributeUpdate(uuid, "datetime", datetime)
        Updates::itemAttributeUpdate(uuid, "description", description)
        Updates::itemAttributeUpdate(uuid, "field11", coredataref)
        Broadcasts::publishItem(uuid)
        Catalyst::itemOrNull(uuid)
    end

    # NxOndates::interactivelyIssueNewTodayOrNull()
    def self.interactivelyIssueNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        Updates::itemInit(uuid, "NxOndate")
        coredataref = CoreDataRefStrings::interactivelyMakeNewReferenceStringOrNull(uuid)
        Updates::itemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Updates::itemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Updates::itemAttributeUpdate(uuid, "description", description)
        Updates::itemAttributeUpdate(uuid, "field11", coredataref)
        Broadcasts::publishItem(uuid)
        Catalyst::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxOndates::toString(item)
    def self.toString(item)
        "🗓️  (#{item["datetime"][0, 10]}) #{"(done, trans, redate)".green} #{TxEngines::prefix2(item)}#{item["description"]}#{CoreDataRefStrings::itemToSuffixString(item)}"
    end

    # NxOndates::ondatesInOrder()
    def self.ondatesInOrder()
        Catalyst::mikuType("NxOndate")
            .sort_by{|item| item["datetime"] }
    end

    # NxOndates::listingItems()
    def self.listingItems()
        NxOndates::ondatesInOrder()
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
    end

    # ------------------
    # Ops

    # NxOndates::access(item)
    def self.access(item)
        CoreDataRefStrings::accessAndMaybeEdit(item["uuid"], item["field11"])
    end

    # NxOndates::redate(item)
    def self.redate(item)
        unixtime = CommonUtils::interactivelyMakeUnixtimeUsingDateCodeOrNull()
        return if unixtime.nil?
        Updates::itemAttributeUpdate(item["uuid"], "datetime", Time.at(unixtime).utc.iso8601)
        DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
    end

    # NxOndates::fsck()
    def self.fsck()
        Catalyst::mikuType("NxOndate").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end
end
