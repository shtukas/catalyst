# encoding: UTF-8

class NxBackups

    # NxBackups::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return nil if description == ""
        period = LucilleCore::askQuestionAnswerAsString("period in days: ").to_f
        Items::init(uuid, "NxBackup")
        Items::setAttribute(uuid, "mikuType", "NxBackup")
        Items::setAttribute(uuid, "mikuType", "NxAnniversary")
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", description)
        Items::setAttribute(uuid, "period", period)
        Items::setAttribute(uuid, "last-done-unixtime", nil)
        Items::itemOrNull(uuid)
    end

    # NxBackups::getItemByDescriptionOrNull(description)
    def self.getItemByDescriptionOrNull(description)
        Index1::mikuTypeItems("NxBackup").select{|item| item["description"] == description }.first
    end

    # NxBackups::toString(item)
    def self.toString(item)
        distance = ""
        unixtime = item["last-done-unixtime"]
        if unixtime then
            distance_in_days = (Time.new.to_i - unixtime).to_f/86400
            if distance_in_days > item["period"] then
                distance = " (last done #{distance_in_days.round(2)} ago)".yellow
            end
        end
        "💾 [backup] #{item["description"]} (every #{item["period"]} days)#{distance}"
    end

    # NxBackups::listingItems()
    def self.listingItems()
        Index1::mikuTypeItems("NxBackup").select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end
end
