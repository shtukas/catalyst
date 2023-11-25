
class NxStickys

    # NxStickys::issue(uuid, description)
    def self.issue(uuid, description)
        DataCenter::itemInit(uuid, "NxSticky")
        DataCenter::setAttribute(uuid, "unixtime", Time.new.to_i)
        DataCenter::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        DataCenter::setAttribute(uuid, "description", description)
        DataCenter::itemOrNull(uuid)
    end

    # NxStickys::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        NxStickys::issue(SecureRandom.uuid, description)
    end

    # ------------------
    # Data

    # NxStickys::toString(item)
    def self.toString(item)
        "♻️  #{item["description"]}"
    end

    # NxStickys::listingItems()
    def self.listingItems()
        DataCenter::mikuType("NxSticky")
            .sort_by{|item| item["unixtime"] }
    end
end
