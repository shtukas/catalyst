
class NxLines

    # NxLines::items()
    def self.items()
        BladeAdaptation::mikuTypeItems("NxLine")
    end

    # NxLines::destroy(uuid)
    def self.destroy(uuid)
        Blades::destroy(uuid)
    end

    # NxLines::issue(line)
    def self.issue(line)
        description = line
        uuid = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        Blades::init("NxFloat", uuid)
        Blades::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Blades::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Blades::setAttribute2(uuid, "description", description)
        BladeAdaptation::getItemOrNull(uuid)
    end

    # NxLines::toString(item)
    def self.toString(item)
        "(line) #{item["description"]}"
    end
end