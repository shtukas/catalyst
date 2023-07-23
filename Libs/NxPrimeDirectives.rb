
class NxPrimeDirectives

    # NxPrimeDirectives::issue(description)
    def self.issue(description)
        uuid = SecureRandom.uuid
        BladesGI::init("NxPrimeDirective", uuid)
        BladesGI::setAttribute2(uuid, "unixtime", Time.new.to_i)
        BladesGI::setAttribute2(uuid, "datetime", Time.new.utc.iso8601)
        BladesGI::setAttribute2(uuid, "description", description)
        BladesGI::itemOrNull(uuid)
    end

    # NxPrimeDirectives::toString(item)
    def self.toString(item)
        "🔅 #{item["description"]}"
    end
end