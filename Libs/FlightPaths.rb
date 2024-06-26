# encoding: UTF-8

class FlightPaths

    # FlightPaths::position(fx17)
    def self.position(fx17)
        # position is a real between 0 and 1, but can be extended to [-1, 0]

        if fx17["type"] == "fixed" then
            return fx17["position"]
        end
        if fx17["type"] == "wave-non-interruption" then
            unixtime = fx17["startUnixtime"]
            deltaTime = Time.new.to_f - unixtime
            return Math.exp(-deltaTime.to_f/86400) - 0.1
        end
        raise "FlightPaths::position: I do not know how to position Fx17: #{fx17}"
    end
end
