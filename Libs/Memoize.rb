
# encoding: UTF-8

$InMemoryX1k23 = {}

# packet:
#     - value     :
#     - expiryTime:

class Memoize

    # Memoize::evaluate(computationId, l)
    def self.evaluate(computationId, l)

        packet = $InMemoryX1k23[computationId]

        if packet then
            if Time.new.to_i < packet["expiryTime"] then
                return packet["value"].clone
            end
        end

        packet = XCache::getOrNull("7bffca74-b01d-45c7-bc31-4c056062b722:#{computationId}")
        if packet then
            packet = JSON.parse(packet)
            if Time.new.to_i < packet["expiryTime"] then
                $InMemoryX1k23[computationId] = packet
                return packet["value"]
            end
        end

        value = l.call()

        packet = {
            "value" => value,
            "expiryTime" => 3600 + rand*3600
        }
        XCache::set("7bffca74-b01d-45c7-bc31-4c056062b722:#{computationId}", JSON.generate(packet))
        $InMemoryX1k23[computationId] = packet

        value
    end
end
