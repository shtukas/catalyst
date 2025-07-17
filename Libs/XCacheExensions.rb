
class XCacheExensions

    # XCacheExensions::trueNoMoreOftenThanNSeconds(key, timeSpanInSeconds)
    def self.trueNoMoreOftenThanNSeconds(key, timeSpanInSeconds)
        unixtime = XCache::getOrDefaultValue(key, "0").to_i
        (Time.new.to_i - unixtime) > timeSpanInSeconds
    end
end
