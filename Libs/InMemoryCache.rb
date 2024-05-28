
# encoding: UTF-8

$InMemoryX1k23 = {}

class InMemoryCache

    # InMemoryCache::getOrNull(key)
    def self.getOrNull(key)
        $InMemoryX1k23[key]
    end

    # InMemoryCache::set(key, value)
    def self.set(key, value)
        $InMemoryX1k23[key] = value
    end
end
