
# encoding: UTF-8

$InMemoryX1k23 = {}

# packet:
#     - value     :
#     - expiryTime:

class Memoize

    # Memoize::evaluate(computationId, l)
    def self.evaluate(computationId, l)

        prefix =  XCache::getOrNull("0D1265D6-2B54-4262-B470-DDB657E53DF5")
        if prefix.nil? then
            prefix = SecureRandom.hex
            XCache::set("0D1265D6-2B54-4262-B470-DDB657E53DF5", prefix)
        end

        packet = $InMemoryX1k23[computationId]

        if packet then
            if Time.new.to_i < packet["expiryTime"] then
                return packet["value"].clone
            end
        end

        packet = XCache::getOrNull("#{prefix}:#{computationId}")
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
        XCache::set("#{prefix}:#{computationId}", JSON.generate(packet))
        $InMemoryX1k23[computationId] = packet

        value
    end
end
