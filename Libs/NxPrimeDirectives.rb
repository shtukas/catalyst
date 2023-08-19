
class NxPrimeDirectives

    # NxPrimeDirectives::issue(description)
    def self.issue(description)
        uuid = SecureRandom.uuid
        Cubes::init("NxPrimeDirective", uuid)
        Cubes::setAttribute2(uuid, "unixtime", Time.new.to_i)
        Cubes::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        Cubes::setAttribute2(uuid, "description", description)
        Cubes::itemOrNull(uuid)
    end

    # NxPrimeDirectives::toString(item)
    def self.toString(item)
        "🔅 #{item["description"]}"
    end
end