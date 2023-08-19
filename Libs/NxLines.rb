
class NxLines

    # NxLines::issue(line)
    def self.issue(line)
        description = line
        uuid = SecureRandom.uuid
        Cubes::init(nil, "NxLine", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::itemOrNull(uuid)
    end

    # NxLines::toString(item)
    def self.toString(item)
        "(line) #{item["description"]}"
    end
end