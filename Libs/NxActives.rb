
class NxActives

    # NxActives::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "payload-37", UxPayloads::makeNewPayloadOrNull(uuid))
        Blades::setAttribute(uuid, "mikuType", "NxActive")
        item = Blades::itemOrNull(uuid)
        item
    end

    # NxActives::icon(item)
    def self.icon(item)
        "🐠"
    end

    # NxActives::toString(item)
    def self.toString(item)
        "#{NxActives::icon(item)} #{item["description"]}#{NxEngine::suffix(item)}"
    end

    # NxActives::listingItems()
    def self.listingItems()
        Blades::mikuType("NxActive")
    end

    # NxActives::completionRatio(item)
    def self.completionRatio(item)
        # If we have a parent, we get the completion ratio of the parent
        # Otherwise, it's zero
        return 0 if item["clique9"].nil?
        parent = Blades::itemOrNull(item["clique9"]["uuid"])
        return 0 if parent.nil?
        NxListings::ratio(parent)
    end

end
