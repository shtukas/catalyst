
$B427FCD6 = nil

class Timings

    # Timings::start()
    def self.start()
        filepath = "#{Config::userHomeDirectory()}/x-space/catalyst-timings.txt"
        File.open(filepath, 'w'){|f| f.write("") }
        $B427FCD6 = Time.new.to_f
    end

    # Timings::lap(message)
    def self.lap(message)
        dt = Time.new.to_f - $B427FCD6
        filepath = "#{Config::userHomeDirectory()}/x-space/catalyst-timings.txt"
        File.open(filepath, 'a'){|f| f.puts("#{message} -> #{dt.round(3)}") }
        $B427FCD6 = Time.new.to_f
    end
end
