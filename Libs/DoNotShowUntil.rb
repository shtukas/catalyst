
class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(item, unixtime)
    def self.setUnixtime(item, unixtime)
        DarkEnergy::patch(item["uuid"], "doNotShowUntil", unixtime)
        # We use XCache for the special purpose of backup items on alexandra
        XCache::set("DoNotShowUntil:#{item["uuid"]}", unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(item)
    def self.getUnixtimeOrNull(item)
        unixtime = DarkEnergy::read(item["uuid"], "doNotShowUntil")
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
        Memoize::evaluate("e8c546fb-b0b0-4b07-a559-7a6d81f9b983:#{item["uuid"]}", lambda{
            unixtime = (DoNotShowUntil::getUnixtimeOrNull(item) || 0)
            return "" if unixtime.nil?
            return "" if Time.new.to_i > unixtime
            " (not shown until: #{Time.at(unixtime).to_s})"
        })
    end
end
