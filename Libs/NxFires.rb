
class NxFires

    # NxFires::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Solingen::init("NxFire", uuid)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        engineuuid = TxEngines::interactivelySelectOneUUIDOrNull()
        Solingen::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Solingen::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Solingen::setAttribute2(uuid, "description", description)
        Solingen::setAttribute2(uuid, "field11", coredataref)
        Solingen::setAttribute2(uuid, "engineuuid", engineuuid)
        Solingen::getItemOrNull(uuid)
    end

    # NxFires::toString(item)
    def self.toString(item)
        "🔥 #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end
end