
class NxFloats

    # ------------------------------------
    # IO
    # ------------------------------------

    # NxFloats::items()
    def self.items()
        N3Objects::getMikuType("NxFloat")
    end

    # NxFloats::commit(item)
    def self.commit(item)
        N3Objects::commit(item)
    end

    # NxFloats::destroy(uuid)
    def self.destroy(uuid)
        N3Objects::destroy(uuid)
    end

    # NxFloats::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxFloat",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref
        }
        puts JSON.pretty_generate(item)
        NxFloats::commit(item)
        item
    end

    # ------------------------------------
    # Data
    # ------------------------------------

    # NxFloats::toString(item)
    def self.toString(item)
        "(float) #{item["description"]}#{CoreData::referenceStringToSuffixString(item["field11"])}"
    end

    # NxFloats::listingItems()
    def self.listingItems()
        NxFloats::items()
            .sort_by{|item| item["unixtime"] }
    end

    # ------------------------------------
    # Ops
    # ------------------------------------

    # NxFloats::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
