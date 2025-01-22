
class DoNotShowUntil
    
    # DoNotShowUntil::getUnixtimeOrNull(id)
    def self.getUnixtimeOrNull(id)
        filepath = "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/DoNotShowUntil/#{id}.data"
        return nil if !File.exist?(filepath)
        IO.read(filepath).strip.to_f
    end

    # DoNotShowUntil::setUnixtime(id, unixtime)
    def self.setUnixtime(id, unixtime)
        filepath = "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/DoNotShowUntil/#{id}.data"
        File.open(filepath, "w"){|f| f.write(unixtime) }
    end

    # DoNotShowUntil::isVisible(id)
    def self.isVisible(id)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(id)
        unixtime.nil? or unixtime <= Time.new.to_i
    end

    # DoNotShowUntil::suffix(item)
    def self.suffix(item)
        unixtime = DoNotShowUntil::getUnixtimeOrNull(item["uuid"])
        return "" if unixtime.nil?
        return "" if unixtime < Time.new.to_i
        " (dot not show until: #{Time.at(unixtime).to_s})".yellow
    end
end
