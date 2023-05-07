
class NxOndates

    # ------------------
    # IO

    # NxOndates::items()
    def self.items()
        BladeAdaptation::mikuTypeItems("NxOndate")
    end

    # NxOndates::destroy(uuid)
    def self.destroy(uuid)
        Blades::destroy(uuid)
    end

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        datetime = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        Blades::init("NxOndate", uuid)
        Blades::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute2(uuid, "datetime", datetime)
        Blades::setAttribute2(uuid, "description", description)
        Blades::setAttribute2(uuid, "field11", coredataref)
        BladeAdaptation::getItemOrNull(uuid)
    end

    # NxOndates::interactivelyIssueNewTodayOrNull()
    def self.interactivelyIssueNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        Blades::init("NxOndate", uuid)
        Blades::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute2(uuid, "description", description)
        Blades::setAttribute2(uuid, "field11", coredataref)
        BladeAdaptation::getItemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxOndates::toString(item)
    def self.toString(item)
        "(ondate: #{item["datetime"][0, 10]}) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # NxOndates::listingItems()
    def self.listingItems()
        NxOndates::items()
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
            .sort_by{|item| item["unixtime"] }
    end

    # ------------------
    # Ops

    # NxOndates::report()
    def self.report()
        system("clear")
        puts "ondates:"
        NxOndates::items()
            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            .each{|item|
                puts NxOndates::toString(item)
            }
        LucilleCore::pressEnterToContinue()
    end

    # NxOndates::access(item)
    def self.access(item)
        CoreData::access(item["uuid"], item["field11"])
    end

    # NxOndates::redate(item)
    def self.redate(item)
        unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
        return if unixtime.nil?
        item["datetime"] = Time.at(unixtime).utc.iso8601
        item["parking"] = nil
        NxOndates::commit(item)
        DoNotShowUntil::setUnixtime(item, unixtime)
    end
end
