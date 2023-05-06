
class NxFires

    # NxFires::items()
    def self.items()
        BladeAdaptation::mikuTypeItems("NxFire")
    end

    # NxFires::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxFires::destroy(uuid)
    def self.destroy(uuid)
        Blades::destroy(uuid)
    end

    # NxFires::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxFire",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref
        }
        puts JSON.pretty_generate(item)
        NxFires::commit(item)
        item
    end

    # NxFires::toString(item)
    def self.toString(item)
        "(🔥) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end
end