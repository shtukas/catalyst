
class NxFronts

    # NxFronts::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxFront", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxFronts::toString(item)
    def self.toString(item)
        "🔸 #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # NxFronts::listingItems()
    def self.listingItems()
        DarkEnergy::mikuType("NxFront")
            .sort_by{|item| item["unixtime"] }
    end

    # NxFronts::locationToFront(location)
    def self.locationToFront(location)
        description = "(nxfront-bufferin) #{File.basename(location)}"
        uuid = SecureRandom.uuid

        DarkEnergy::init("NxFront", uuid)

        coredataref = CoreData::locationToAionPointCoreDataReference(location)

        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::itemOrNull(uuid)
    end    

    # NxFronts::importFromBuffer()
    def self.importFromBuffer()
        folder = "#{Config::pathToGalaxy()}/DataHub/NxFronts-BufferIn"
        LucilleCore::locationsAtFolder(folder)
            .each{|location| 
                NxFronts::locationToFront(location) 
                LucilleCore::removeFileSystemLocation(location)
            }
    end
end