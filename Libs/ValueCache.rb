# encoding: UTF-8
 
class ValueCache
 
    # ValueCache::getOrNull(key)
    def self.getOrNull(key)
        value = XCache::getOrNull("7e888550-27b3-49bf-bc54-8bf6c8ab3cd3:#{key}")
        return nil if value.nil?
        JSON.parse(value)
    end
 
    # ValueCache::set(key, value)
    def self.set(key, value)
        XCache::set("7e888550-27b3-49bf-bc54-8bf6c8ab3cd3:#{key}", JSON.generate(value))
    end
 
    # ValueCache::destroy(key)
    def self.destroy(key)
        XCache::destroy("7e888550-27b3-49bf-bc54-8bf6c8ab3cd3:#{key}")
    end
end