
class NxTasks

    # NxTasks::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "payload-uuid-1141", UxPayloads::interactivelyIssueNewGetReferenceOrNull())
        Items::setAttribute(uuid, "taskpos-49", rand)
        Items::setAttribute(uuid, "mikuType", "NxTask")
        item = Items::itemOrNull(uuid)
        Fsck::fsckItemOrError(item, false)
        item
    end

    # ----------------------
    # Data

    # NxTasks::icon()
    def self.icon()
        "🔹"
    end

    # NxTasks::toString(item)
    def self.toString(item)
        "#{NxTasks::icon()} #{item["description"]}"
    end

    # NxTasks::listingItems()
    def self.listingItems()
        Items::mikuType("NxTask")
            .sort_by{|item| item["taskpos-49"] }
            .first(5)
    end

    # NxTasks::interactivelyDecideFocus23OrNull()
    def self.interactivelyDecideFocus23OrNull()
        options = [
            "priority",
            "happening",
            "today",
            "short-project-with-deadline",
            "short-project",
            "long-project"
        ]
        LucilleCore::selectEntityFromListOfEntitiesOrNull("focus", options)
    end

    # ----------------------
    # Ops

    # NxTasks::interactivelySetFocus23OrNothing(item)
    def self.interactivelySetFocus23OrNothing(item)
        focus = NxTasks::interactivelyDecideFocus23OrNull()
        return if focus.nil?
        Items::setAttribute(item["uuid"], "focus-23", focus)
    end

end
