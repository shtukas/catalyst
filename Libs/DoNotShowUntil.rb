
class DoNotShowUntil

    # DoNotShowUntil::setUnixtime(item, unixtime)
    def self.setUnixtime(item, unixtime)
        Events::publishDoNotShowUntil(item, unixtime)
    end

    # DoNotShowUntil::getDataSet() # Map[targetId, unixtime]
    def self.getDataSet()
        trace = EventTimelineReader::lastTraceForCaching()
        dataset = InMemoryCache::getOrNull("3e9efc9a-785b-44f7-8b87-7dbe92eee8df:#{trace}")
        if dataset then
            return dataset
        end

        cachePrefix = "DoNotShowUntil-491E-A2AB-6CB93205787C"
        unit = {}
        combinator = lambda{|data, event|
            if event["eventType"] == "DoNotShowUntil" then
                data[event["targetId"]] = event["unixtime"]
            end
            data
        }
        dataset = EventTimelineReader::extract(cachePrefix, unit, combinator)

        InMemoryCache::set("3e9efc9a-785b-44f7-8b87-7dbe92eee8df:#{trace}", dataset)
        dataset
    end

    # DoNotShowUntil::getUnixtimeOrNull(item)
    def self.getUnixtimeOrNull(item)
        DoNotShowUntil::getDataSet()[item["uuid"]]
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
