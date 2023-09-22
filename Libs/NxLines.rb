
class NxLines

    # NxLines::issue(line)
    def self.issue(line)
        description = line
        uuid = SecureRandom.uuid
        Events::publishItemInit("NxLine", uuid)
        Events::publishItemAttributeUpdate(uuid, "unixtime", Time.new.to_i)
        Events::publishItemAttributeUpdate(uuid, "datetime", Time.new.utc.iso8601)
        Events::publishItemAttributeUpdate(uuid, "description", description)
        Catalyst::itemOrNull(uuid)
    end

    # NxLines::toString(item)
    def self.toString(item)
        "(line) #{item["description"]}#{TxCores::suffix(item)}"
    end
end