
class NxOndates

    # ------------------
    # IO

    # NxOndates::items()
    def self.items()
        N3Objects::getMikuType("NxOndate")
    end

    # NxOndates::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxOndates::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        datetime = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOndate",
            "unixtime"    => Time.new.to_i,
            "datetime"    => datetime,
            "description" => description,
            "field11"     => coredataref
        }
        puts JSON.pretty_generate(item)
        NxOndates::commit(item)
        item
    end

    # NxOndates::interactivelyIssueNewTodayOrNull()
    def self.interactivelyIssueNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("today (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOndate",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref
        }
        NxOndates::commit(item)
        item
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
        CoreData::access(item["field11"])
    end

    # NxOndates::redate(item)
    def self.redate(item)
        unixtime = CommonUtils::interactivelySelectUnixtimeUsingDateCodeOrNull()
        item["datetime"] = Time.at(unixtime).utc.iso8601
        item["parking"] = nil
        NxOndates::commit(item)
        DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
    end
end
