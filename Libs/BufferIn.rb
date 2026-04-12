
class BufferIn

    # BufferIn::issueNew(filepath)
    def self.issueNew(filepath)
        description = File.basename(filepath)
        uuid = SecureRandom.uuid
        Blades::init(uuid)
        Blades::setAttribute(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute(uuid, "description", description)
        Blades::setAttribute(uuid, "payload-37", UxPayloads::locationToPayload(uuid, filepath))
        Blades::setAttribute(uuid, "mikuType", "BufferIn")
        item = Blades::itemOrNull(uuid)
        item
    end

    # BufferIn::import()
    def self.import()
        repository = "#{Config::userHomeDirectory()}/Desktop/Buffer-In"
        return if !File.exist?(repository)
        LucilleCore::locationsAtFolder(repository).each{|location|
            next if File.basename(location).start_with?('.')
            puts "importing location: #{location}".yellow
            BufferIn::issueNew(location)
            LucilleCore::removeFileSystemLocation(location)
        }
    end

    # BufferIn::toString(item)
    def self.toString(item)
        "🥐 #{item["description"]}"
    end

    # BufferIn::listingItems()
    def self.listingItems()
        if BankDerivedData::recoveredAverageHoursPerDay("95580b8d-b62f-4fa2-88ad-aefdc3ca450c") > 1 then
            return []
        end
        items = Blades::mikuType("BufferIn")
        items = FrontPage::ensure_and_apply_global_posionning_order(items)
        items.reduce([]){|selected, item|
            if selected.size >= 5 then
                selected
            else
                if DoNotShowUntil::isVisible(item) and BankDerivedData::recoveredAverageHoursPerDay(item["uuid"]) < 1 then
                    selected + [item]
                else
                    selected
                end
            end
        }
    end
end
