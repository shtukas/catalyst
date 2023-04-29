
class NxFrontOrdinals

    # NxFrontOrdinals::items()
    def self.items()
        N3Objects::getMikuType("NxFrontOrdinal")
    end

    # NxFrontOrdinals::issue(targetuuid, ordinal)
    def self.issue(targetuuid, ordinal)
        item = {
            "uuid"          => SecureRandom.uuid,
            "mikuType"      => "NxFrontOrdinal",
            "targetuuid"    => targetuuid,
            "targetordinal" => ordinal
        }
        N3Objects::commit(item)
        item
    end

    # NxFrontOrdinals::destroyByTargetUUID(targetuuid)
    def self.destroyByTargetUUID(targetuuid)
        NxFrontOrdinals::items()
            .select{|item| item["targetuuid"] == targetuuid }
            .each{|item| N3Objects::destroy(item["uuid"]) }
    end

    # NxFrontOrdinals::getOrdinalByTargetuuid(targetuuid)
    def self.getOrdinalByTargetuuid(targetuuid)
        item = NxFrontOrdinals::items()
                .select{|item| item["targetuuid"] == targetuuid }
                .first
        return item["targetordinal"]
        raise "(error: c419fc28-873b-47e3-a6b2-f1b28848918e)"
    end

    # NxFrontOrdinals::garbageCollection(front)
    def self.garbageCollection(front)
        NxFrontOrdinals::items().each{|item|
            if !front.map{|i| i["uuid"] }.include?(item["uuid"]) then
                N3Objects::destroy(item["uuid"])
            end
        }
    end
end
