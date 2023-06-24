
# encoding: UTF-8

$InMemoryX1k23 = {}

# packet:
#     - value :

$Queue9CD2 = []

# d2:
#     - computationId :
#     - lambda        :

class Memoize

    # Memoize::registerLaterComputation(computationId, l)
    def self.registerLaterComputation(computationId, l)
        return if $Queue9CD2.map{|d2| d2["computationId"] }.include?(computationId)
        $memoize_semaphore_1.synchronize {
            $Queue9CD2 << {
                "computationId" => computationId,
                "lambda" => l
            }
        }
    end

    # Memoize::evaluate(computationId, l)
    def self.evaluate(computationId, l)
        Memoize::registerLaterComputation(computationId, l)

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

Thread.new {
    sleep 12
    loop {
        next if $Queue9CD2.empty?
        d2 = nil
        $memoize_semaphore_1.synchronize {
            d2 = $Queue9CD2.shift
        }
        value = d2["lambda"].call()
        packet = {
            "value" => value
        }
        XCache::set(d2["computationId"], JSON.generate(packet))
        $InMemoryX1k23[d2["computationId"]] = packet
        sleep 0.1
    }
}
