
class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(item, unixtime)
    def self.setUnixtime(item, unixtime)
        # We start by using XCache for the special purpose of backup items on alexandra
        XCache::set("DoNotShowUntil:#{item["uuid"]}", unixtime)

        item["doNotShowUntil"] = unixtime
        N3Objects::commit(item)
    end

    # DoNotShowUntil::getUnixtimeOrNull(item)
    def self.getUnixtimeOrNull(item)
        return item["doNotShowUntil"] if item["doNotShowUntil"]
        return XCache::getOrNull("DoNotShowUntil:#{item["uuid"]}").to_f if XCache::getOrNull("DoNotShowUntil:#{item["uuid"]}")
        nil
    end

    # DoNotShowUntil::isVisible(item)
    def self.isVisible(item)
        Time.new.to_i >= (DoNotShowUntil::getUnixtimeOrNull(item) || 0)
    end

    # DoNotShowUntil::suffixString(item)
    def self.suffixString(item)
        unixtime = (DoNotShowUntil::getUnixtimeOrNull(item) || 0)
        return "" if unixtime.nil?
        return "" if Time.new.to_i > unixtime
        " (not shown until: #{Time.at(unixtime).to_s})"
    end
end
