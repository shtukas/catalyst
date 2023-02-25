
class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(uuid, unixtime)
    def self.setUnixtime(uuid, unixtime)
        N2KVStore::set("DoNotShowUntil:#{uuid}", unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(uuid)
    def self.getUnixtimeOrNull(uuid)
        N2KVStore::getOrNull("DoNotShowUntil:#{uuid}")
    end

    # DoNotShowUntil::isVisible(uuid)
    def self.isVisible(uuid)
        Time.new.to_i >= (DoNotShowUntil::getUnixtimeOrNull(uuid) || 0)
    end

    # DoNotShowUntil::suffixString(item)
    def self.suffixString(item)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(item["uuid"])
        return "" if unixtime.nil?
        return "" if Time.new.to_i > unixtime
        " (not shown until: #{Time.at(unixtime).to_s})"
    end
end
