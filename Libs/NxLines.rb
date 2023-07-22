
class NxLines

    # NxLines::issue(line)
    def self.issue(line)
        description = line
        uuid = SecureRandom.uuid
        BladesGI::init("NxLine", uuid)
        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::itemOrNull(uuid)
    end

    # NxLines::toString(item)
    def self.toString(item)
        "(line) #{item["description"]}"
    end
end