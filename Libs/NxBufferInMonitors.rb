
class NxBufferInMonitors

    # "uuid": "480692a2-cf70-4ad6-ad34-64c88818d688"
    # "mikuType": "NxBufferInMonitor"

    # NxBufferInMonitors::toString(item)
    def self.toString(item)
        ratiostring = "[#{"%6.2f" % NxBufferInMonitors::ratio()}]".green
        "🔅 #{ratiostring} BufferIn (Process all elements)"
    end

    # NxBufferInMonitors::ratio()
    def self.ratio()
        [Bank1::recoveredAverageHoursPerDay("480692a2-cf70-4ad6-ad34-64c88818d688"), 0].max.to_f/0.5
    end

    # NxBufferInMonitors::bufferInCardinal()
    def self.bufferInCardinal()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Buffer-In")
            .select{|location| !File.basename(location).start_with?(".") }
            .size
    end

    # NxBufferInMonitors::muiItems()
    def self.muiItems()
        return [] if NxBufferInMonitors::bufferInCardinal() == 0
        return [] if NxBufferInMonitors::ratio() >= 1
        Cubes1::mikuType("NxBufferInMonitor")
    end

    # NxBufferInMonitors::metric(item)
    def self.metric(item)
        [0, 0.5 - Bank1::recoveredAverageHoursPerDay("480692a2-cf70-4ad6-ad34-64c88818d688")]
    end
end
