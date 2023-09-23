
class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(item, unixtime)
    def self.setUnixtime(item, unixtime)
        Events::publishDoNotShowUntil(item, unixtime)
        XCache::set("747a75ad-05e7-4209-a876-9fe8a86c40dd:#{item["uuid"]}", unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(item)
    def self.getUnixtimeOrNull(item)
        unixtime = EventTimelineDatasets::doNotShowUntil()[item["uuid"]]
        return unixtime if unixtime
        unixtime = XCache::getOrNull("747a75ad-05e7-4209-a876-9fe8a86c40dd:#{item["uuid"]}")
        return unixtime.to_i if unixtime
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
