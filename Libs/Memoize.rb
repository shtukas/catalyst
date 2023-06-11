
# encoding: UTF-8

$InMemoryX1k23 = {}

# packet:
#     - unixtime: 
#     - value   :

class Memoize

    # Memoize::evaluate(computationId, l, retentionTime)
    def self.evaluate(computationId, l, retentionTime)
        packet = $InMemoryX1k23[computationId]

        if packet then
            if (Time.new.to_i - packet["unixtime"]) < retentionTime then
                return packet["value"]
            end
        end

        value = l.call()

        packet = {
            "unixtime" => Time.new.to_i,
            "value"    => value
        }

        $InMemoryX1k23[computationId] = packet

        value
    end
end
