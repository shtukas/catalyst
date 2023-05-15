
class NxFloats

    # NxFloats::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Solingen::init("NxFloat", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::getItemOrNull(uuid)
    end

    # ------------------------------------
    # Data
    # ------------------------------------

    # NxFloats::toString(item)
    def self.toString(item)
        "(floa) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # ------------------------------------
    # Ops
    # ------------------------------------

    # NxFloats::access(item)
    def self.access(item)
        CoreData::access(item["uuid"], item["field11"])
    end
end
