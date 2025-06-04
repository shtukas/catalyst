
# encoding: UTF-8

class ValueCacheWithExpiry

    # ValueCacheWithExpiry::getOrNull(key, validity_period)
    def self.getOrNull(key, validity_period)
        packet = XCache::getOrNull("7e888550-27b3-49bf-bc54-8bf6c8ab3cd2:#{key}")
        return nil if packet.nil?
        packet = JSON.parse(packet)
        return nil if (Time.new.to_i - packet["unixtime"]) > validity_period
        packet["data"]
    end

    # ValueCacheWithExpiry::set(key, data)
    def self.set(key, data)
        packet = {
            "unixtime" => Time.new.to_i,
            "data" => data
        }
        XCache::set("7e888550-27b3-49bf-bc54-8bf6c8ab3cd2:#{key}", JSON.generate(packet))
    end

    # ValueCacheWithExpiry::destroy(key)
    def self.destroy(key)
        XCache::destroy("7e888550-27b3-49bf-bc54-8bf6c8ab3cd2:#{key}")
    end
end
