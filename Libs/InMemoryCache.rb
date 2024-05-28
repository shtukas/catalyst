
# encoding: UTF-8

$InMemoryX1k23 = {}

class InMemoryCache

    # InMemoryCache::getOrNull(key)
    def self.getOrNull(key)
        if $InMemoryX1k23[key] then
            return $InMemoryX1k23[key].clone
        end

        value = XCache::getOrNull("3f74467c-e23d-49a9-bfab-6863264cdab8:#{key}")

        if value then
            value = JSON.parse(value)[0]
            $InMemoryX1k23[key] = value
            value
        else
            nil
        end
    end

    # InMemoryCache::set(key, value)
    def self.set(key, value)
        $InMemoryX1k23[key] = value
        XCache::set("3f74467c-e23d-49a9-bfab-6863264cdab8:#{key}", JSON.generate([value]))
    end
end
