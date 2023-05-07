
class NxFloats

    # ------------------------------------
    # IO
    # ------------------------------------

    # NxFloats::items()
    def self.items()
        BladeAdaptation::mikuTypeItems("NxFloat")
    end

    # NxFloats::destroy(uuid)
    def self.destroy(uuid)
        Blades::destroy(uuid)
    end

    # NxFloats::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        Blades::init("NxFloat", uuid)
        Blades::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute2(uuid, "description", description)
        Blades::setAttribute2(uuid, "field11", coredataref)
        BladeAdaptation::getItemOrNull(uuid)
    end

    # ------------------------------------
    # Data
    # ------------------------------------

    # NxFloats::toString(item)
    def self.toString(item)
        "(float) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # ------------------------------------
    # Ops
    # ------------------------------------

    # NxFloats::access(item)
    def self.access(item)
        CoreData::access(item["uuid"], item["field11"])
    end
end
