
class NxNotifications

    # NxNotifications::issue(line)
    def self.issue(line)
        uuid = SecureRandom.uuid
        Items::init(uuid)
        Items::setAttribute(uuid, "unixtime", Time.new.to_i)
        Items::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Items::setAttribute(uuid, "description", line)
        Items::setAttribute(uuid, "mikuType", "NxNotification")
        item = Items::itemOrNull(uuid)
        item
    end

    # NxNotifications::pickup()
    def self.pickup()
        directory = "#{Config::pathToGalaxy()}/DataHub/Dispatch/letterbox"
        LucilleCore::locationsAtFolder(directory)
            .select{|location| location[-11, 11] == ".letter.txt" }
            .each{|filepath| 
                NxNotifications::issue(IO.read(filepath).strip)
                FileUtils.rm(filepath)
            }
    end

    # NxNotifications::toString(item)
    def self.toString(item)
        "✉️  #{item["description"]}"
    end

    # NxNotifications::listingItems()
    def self.listingItems()
        Items::mikuType("NxNotification")
    end
end
