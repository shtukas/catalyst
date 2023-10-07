
class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(itemuuid, unixtime)
    def self.setUnixtime(itemuuid, unixtime)
        Broadcasts::publishDoNotShowUntil(itemuuid, unixtime)
        XCache::set("747a75ad-05e7-4209-a876-9fe8a86c40dd:#{itemuuid}", unixtime)
        puts "do not display '#{itemuuid}' until #{Time.at(unixtime).utc.iso8601}"
    end

    # DoNotShowUntil::getUnixtimeOrNull(itemuuid)
    def self.getUnixtimeOrNull(itemuuid)
        unixtime = EventTimelineDatasets::doNotShowUntil()[itemuuid]
        return unixtime if unixtime
        unixtime = XCache::getOrNull("747a75ad-05e7-4209-a876-9fe8a86c40dd:#{itemuuid}")
        return unixtime.to_i if unixtime
        nil
    end

    # DoNotShowUntil::isVisible(item)
    def self.isVisible(item)
        Time.new.to_i >= (DoNotShowUntil::getUnixtimeOrNull(item["uuid"]) || 0)
    end

    # DoNotShowUntil::suffixString(item)
    def self.suffixString(item)
        unixtime = (DoNotShowUntil::getUnixtimeOrNull(item["uuid"]) || 0)
        return "" if unixtime.nil?
        return "" if Time.new.to_i > unixtime
        " (not shown until: #{Time.at(unixtime).to_s})"
    end
end
