
class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(item, unixtime)
    def self.setUnixtime(item, unixtime)
        # We start by using XCache for the special purpose of backup items on alexandra
        XCache::set(item["uuid"], unixtime)

        item["doNotShowUntil"] = unixtime
        N3Objects::commit(item)
    end

    # DoNotShowUntil::isVisible(item)
    def self.isVisible(item)
        Time.new.to_i >= (item["doNotShowUntil"] || 0)
    end

    # DoNotShowUntil::suffixString(item)
    def self.suffixString(item)
        unixtime = (item["doNotShowUntil"] || (XCache::getOrNull(item["uuid"]) || 0)).to_f
        return "" if unixtime.nil?
        return "" if Time.new.to_i > unixtime
        " (not shown until: #{Time.at(unixtime).to_s})"
    end
end
