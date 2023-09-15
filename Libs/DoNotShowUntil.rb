
class DoNotShowUntil

    # DoNotShowUntil::getDataSet()
    def self.getDataSet()
        cachePrefix = "DoNotShowUntil-491E-A2AB-6CB93205787C"
        unit = {}
        combinator = lambda{|data, event|
            if event["eventType"] == "DoNotShowUntil" then
                data[event["targetId"]] = event["unixtime"]
            end
            data
        }
        EventTimelineReader::extract(cachePrefix, unit, combinator)
        # data: Map[targetId, unixtime]
    end

    # DoNotShowUntil::setUnixtime(item, unixtime)
    def self.setUnixtime(item, unixtime)
        Events::publishDoNotShowUntil(item, unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(item)
    def self.getUnixtimeOrNull(item)
        trace = EventTimelineReader::lastTraceForCaching()
        unxitime = XCache::getOrNull("11ef13b1-b3b7-48e8-8a4d-6caab4fcec52:#{trace}:#{item["uuid"]}")
        if unxitime then
            return unxitime.to_i
        end
        unxitime = DoNotShowUntil::getDataSet()[item["uuid"]]
        if unxitime then
            XCache::set("11ef13b1-b3b7-48e8-8a4d-6caab4fcec52:#{trace}:#{item["uuid"]}", unxitime)
        end
        unxitime
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
