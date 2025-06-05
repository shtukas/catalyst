
class NxLines

    # NxLines::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
        return nil if line == ""
        Items::init(uuid)
        Items::setAttribute(uuid, "mikuType", "NxLine")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "line", line)
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxLines::toString(item)
    def self.toString(item)
        "✒️  #{item["line"]}"
    end

    # NxLines::listingItems()
    def self.listingItems()
        Items::mikuType("NxLine")
    end
end
