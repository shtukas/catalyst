
# encoding: UTF-8

$InMemoryX1k23 = {}

# packet:
#     - expiryTime :
#     - value      :

class Memoize

    # Memoize::evaluate(computationId, l, retentionTime)
    def self.evaluate(computationId, l, retentionTime)
        packet = $InMemoryX1k23[computationId]

        if packet then
            if Time.new.to_i < packet["expiryTime"] then
                return packet["value"]
            end
        end

        packet = XCache::getOrNull(computationId)
        if packet then
            packet = JSON.parse(packet)
            if Time.new.to_i < packet["expiryTime"] then
                $InMemoryX1k23[computationId] = packet
                return packet["value"].clone
            end
        end

        value = l.call()

        packet = {
            "expiryTime" => Time.new.to_i + retentionTime,
            "value"    => value
        }

        XCache::set(computationId, JSON.generate(packet))
        $InMemoryX1k23[computationId] = packet

        value
    end

    # Memoize::decache(computationId)
    def self.decache(computationId)
        XCache::destroy(computationId)
        $InMemoryX1k23[computationId].nil?
    end

    # Memoize::retentionTime(t1, t2)
    def self.retentionTime(t1, t2)
        t1 + rand*(t2 - t1)
    end
end
