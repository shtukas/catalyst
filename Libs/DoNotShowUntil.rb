
class DoNotShowUntil

    # DoNotShowUntil::event(item, unixtime)
    def self.event(item, unixtime)
        {
            "uuid"      => SecureRandom.uuid,
            "eventType" => "DoNotShowUntil",
            "targetId"  => item["uuid"],
            "unixtime"  => unixtime
        }
    end

    # DoNotShowUntil::getDataSet()
    def self.getDataSet()
        cachePrefix = "A057CBE4-9F58-491E-A2AB-6CB93205787C"
        unit = {}
        combinator = lambda{|data, event|
            if event["eventType"] == "DoNotShowUntil" then
                data[event["targetId"]] = event["unixtime"]
            end
            data
        }
        EventTimelineReducer::extract(cachePrefix, unit, combinator)
        # data: Map[targetId, unixtime]
    end

    # DoNotShowUntil::setUnixtime(item, unixtime)
    def self.setUnixtime(item, unixtime)
        # We use XCache for the special purpose of backup items on alexandra
        XCache::set("DoNotShowUntil:#{item["uuid"]}", unixtime)
        EventPublisher::publish(DoNotShowUntil::event(item, unixtime))
        return if item["mikuType"] == "Backup"
        Cubes::setAttribute2(item["uuid"], "doNotShowUntil", unixtime)
    end

    # DoNotShowUntil::getUnixtimeOrNull(item)
    def self.getUnixtimeOrNull(item)
        unixtime = item["doNotShowUntil"]
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
