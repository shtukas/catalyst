# encoding: UTF-8

class NxBackups

    # NxBackups::getItemByDescriptionOrNull(description)
    def self.getItemByDescriptionOrNull(description)
        Items::mikuType("NxBackup").select{|item| item["description"] == description }.first
    end

    # NxBackups::toString(item)
    def self.toString(item)
        "💾 [backup] #{item["description"]} (every #{item["period"]} days)"
    end

    # NxBackups::next_unixtime(item)
    def self.next_unixtime(item)
        Time.new.to_i + item["period"]*86400
    end

    # NxBackups::processNotificationChannel()
    def self.processNotificationChannel()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Nx20-MessageService/abf95a7b-36a5-41af-bb98-d8638c68fca6").each{|filepath|
            message = JSON.parse(IO.read(filepath))
            puts JSON.pretty_generate(message)
            description = message["payload"]["description"]
            item = NxBackups::getItemByDescriptionOrNull(description)
            next if item.nil?
            ListingPositioning::reposition(item)
            FileUtils.rm(filepath)
        }
    end
end
