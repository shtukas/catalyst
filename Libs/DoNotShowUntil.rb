
class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(item, unixtime)
    def self.setUnixtime(item, unixtime)
        Solingen::setAttribute2(item["uuid"], "doNotShowUntil", unixtime)
        # We use XCache for the special purpose of backup items on alexandra
        XCache::set("DoNotShowUntil:#{item["uuid"]}", unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(item)
    def self.getUnixtimeOrNull(item)
        unixtime = Solingen::getAttributeOrNull2(item["uuid"], "doNotShowUntil")
        return unixtime if unixtime
        unixtime = XCache::getOrNull("DoNotShowUntil:#{item["uuid"]}")
        return unixtime.to_f if unixtime
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
