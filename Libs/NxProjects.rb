
class NxProjects

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "mikuType", "NxProject")
        Items::itemOrNull(uuid)
    end

    # ------------------
    # Data

    # NxProjects::icon(item)
    def self.icon(item)
        "⛵️"
    end

    # NxProjects::toString(item)
    def self.toString(item)
        "#{NxProjects::icon(item)} #{item["description"]}"
    end

    # NxProjects::listingItems()
    def self.listingItems()
        Items::mikuType("NxProject")
    end
end
