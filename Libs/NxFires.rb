
class NxFires

    # NxFires::items()
    def self.items()
        BladeAdaptation::mikuTypeItems("NxFire")
    end

    # NxFires::destroy(uuid)
    def self.destroy(uuid)
        Blades::destroy(uuid)
    end

    # NxFires::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        Blades::init("NxFire", uuid)
        Blades::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute2(uuid, "description", description)
        Blades::setAttribute2(uuid, "field11", coredataref)
        BladeAdaptation::getItemOrNull(uuid)
    end

    # NxFires::toString(item)
    def self.toString(item)
        "(🔥) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end
end