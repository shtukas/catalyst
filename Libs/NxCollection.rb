
class NxCollections

    # NxCollections::issue(description)
    def self.issue(description)
        uuid = SecureRandom.uuid
        Events::publishItemInit("NxCollection", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Catalyst::itemOrNull(uuid)
    end

    # NxCollections::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxCollections::issue(description)
    end

    # NxCollections::toString(item)
    def self.toString(item)
        "✨ #{item["description"]}"
    end

    # NxCollections::listingItems()
    def self.listingItems()
        Catalyst::mikuType("NxCollection").sort_by{|item| item["unixtime"] }
    end
end