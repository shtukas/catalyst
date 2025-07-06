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
        Items::mikuType("NxBackup").select{|item| item["description"] == description }.first
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
        Items::mikuType("NxBackup").select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # NxBackups::notificationChannelHasMessages()
    def self.notificationChannelHasMessages()
        flag = LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Nx20-MessageService/abf95a7b-36a5-41af-bb98-d8638c68fca6")
                .select{|filepath| filepath[-5, 5] == ".json" }
                .empty?
        !flag
    end

    # NxBackups::processNotificationChannel()
    def self.processNotificationChannel()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Nx20-MessageService/abf95a7b-36a5-41af-bb98-d8638c68fca6")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .each{|filepath|
                message = JSON.parse(IO.read(filepath))
                puts JSON.pretty_generate(message)
                description = message["payload"]["description"]
                item = NxBackups::getItemByDescriptionOrNull(description)
                next if item.nil?
                NxBalls::stop(item)
                DoNotShowUntil::setUnixtime(item["uuid"], Time.new.to_i + item["period"] * 86400)
                Items::setAttribute(item["uuid"], "last-done-unixtime", Time.new.to_i)
                FileUtils.rm(filepath)
            }
    end
end
