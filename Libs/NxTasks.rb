
class NxTasks

    # NxTasks::nextOrdinal()
    def self.nextOrdinal()
        1.5
    end

    # NxTasks::interactivelyIssueNewProjectOrNull()
    def self.interactivelyIssueNewProjectOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "px36-ordinal", NxTasks::nextOrdinal())
        Items::setAttribute(uuid, "mikuType", "NxTask")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # NxTasks::icon()
    def self.icon()
        "🔹"
    end

    # NxTasks::toString(item)
    def self.toString(item)
        "#{NxTasks::icon()} #{item["description"]}"
    end

    # NxTasks::ratio(item)
    def self.ratio(item)
        BankDerivedData::recoveredAverageHoursPerDay(item["uuid"])
    end

    # NxTasks::listingItems()
    def self.listingItems()
        Items::mikuType("NxTask")
            .sort_by{|item| item["px36-ordinal"] }
            .first(5)
    end
end
