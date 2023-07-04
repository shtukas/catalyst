
class NxFronts

    # NxFronts::issueWithDescription(description)
    def self.issueWithDescription(description)
        uuid = SecureRandom.uuid
        DarkEnergy::init("NxFront", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull()
        DarkEnergy::patch(uuid, "unixtime", Time.new.to_i)
        DarkEnergy::patch(uuid, "datetime", Time.new.utc.iso8601)
        DarkEnergy::patch(uuid, "description", description)
        DarkEnergy::patch(uuid, "field11", coredataref)
        DarkEnergy::itemOrNull(uuid)
    end

    # NxFronts::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxFronts::issueWithDescription(description)
    end

    # NxFronts::toString(item)
    def self.toString(item)
        "☀️  #{item["description"]}#{CoreData::itemToSuffixString(item)}"
    end

    # NxFronts::maintenance()
    def self.maintenance()
        if !XCache::getFlag("eea69539-f90d-4400-9d05-d806f97784a6:#{CommonUtils::today()}") then
            item = NxFronts::issueWithDescription(Time.new.to_s)
            ListingPositions::set(item, ListingPositions::nextPosition())
            XCache::setFlag("eea69539-f90d-4400-9d05-d806f97784a6:#{CommonUtils::today()}", true)
        end
    end
end