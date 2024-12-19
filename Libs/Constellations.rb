
class Constellation

    # Constellation::constellation(targetuuid, description, spreadTimeSpanInDays, totalCapsuleTimeInHours)
    def self.constellation(targetuuid, description, spreadTimeSpanInDays, totalCapsuleTimeInHours)
        singleCapsuleDurationInSeconds = (3600 * totalCapsuleTimeInHours).to_f/20
        startTimes = (1..20).map{|i| Time.new.to_i + 12*3600 + rand * 86400*spreadTimeSpanInDays }
        startTimes.sort.map{|start|
            puts "constellation: launching capsule for `#{description}` at #{Time.at(start).utc.iso8601}"
            NxTimeCapsules::issue("capsule for: #{description}", -singleCapsuleDurationInSeconds, start, targetuuid)
        }
    end

    # Constellation::constellationWithTimeControl(targetuuid, description, spreadTimeSpanInDays, totalCapsuleTimeInHours, timeToNextConstellationInDays)
    def self.constellationWithTimeControl(targetuuid, description, spreadTimeSpanInDays, totalCapsuleTimeInHours, timeToNextConstellationInDays)
        return if Constellation::getNextConstellationUnixtime(targetuuid) > Time.new.to_i
        Constellation::constellation(targetuuid, description, spreadTimeSpanInDays, totalCapsuleTimeInHours)
        Constellation::setNextConstellationUnixtime(targetuuid, Time.new.to_i + timeToNextConstellationInDays*86400)
    end

    # Constellation::getNextConstellationUnixtime(targetuuid)
    def self.getNextConstellationUnixtime(targetuuid)
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Catalyst/data/constellation-times/#{targetuuid}.unixtime"
        return 0 if !File.exist?(filepath)
        IO.read(filepath).to_i
    end

    # Constellation::setNextConstellationUnixtime(targetuuid, unixtime)
    def self.setNextConstellationUnixtime(targetuuid, unixtime)
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Catalyst/data/constellation-times/#{targetuuid}.unixtime"
        File.open(filepath, "w"){|f| f.puts(unixtime) }
    end
end
