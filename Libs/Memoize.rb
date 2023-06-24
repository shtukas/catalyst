
# encoding: UTF-8

$InMemoryX1k23 = {}

# packet:
#     - value :

class Memoize

    # Memoize::evaluate(computationId, l)
    def self.evaluate(computationId, l)

        packet = $InMemoryX1k23[computationId]

        if packet then
            return packet["value"].clone
        end

        packet = XCache::getOrNull(computationId)
        if packet then
            packet = JSON.parse(packet)
            $InMemoryX1k23[computationId] = packet
            return packet["value"]
        end

        value = l.call()

        packet = {
            "value" => value
        }
        XCache::set(computationId, JSON.generate(packet))
        $InMemoryX1k23[computationId] = packet

        value
    end
end
