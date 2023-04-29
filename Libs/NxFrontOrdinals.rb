
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

    # NxFrontOrdinals::dataManagement()
    def self.dataManagement()
        return if NxFrontOrdinals::items().empty?
        maxordinal = NxFrontOrdinals::items().map{|item| item["targetordinal"] }.max
        return if maxordinal < 100
        NxFrontOrdinals::items().map{|item|
            item["targetordinal"] = item["targetordinal"] * 0.5
            N3Objects::commit(item)
        }
    end

    # NxFrontOrdinals::rotateCatalystItem(catalystItem)
    def self.rotateCatalystItem(catalystItem)
        nextOrdinal = (([1] + NxFrontOrdinals::items().map{|i| i["targetordinal"] }).max + 1).floor
        NxFrontOrdinals::items()
            .select{|item| item["targetuuid"] == catalystItem["uuid"] }
            .each{|item| N3Objects::destroy(item["uuid"]) }
        NxFrontOrdinals::issue(catalystItem["uuid"], nextOrdinal)
    end
end
