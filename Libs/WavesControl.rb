
#{
#    "uuid": "12345",
#    "displayTime": 12
#}

class WavesControl

    # WavesControl::getObject(uuid)
    def self.getObject(uuid)
        Find.find("#{Config::pathToCatalystDataRepository()}/Wave-Control") do |path|
            next if path[-5, 5] != ".json"
            object = JSON.parse(IO.read(path))
            next if object["uuid"] != uuid
            return object
        end
        object = {
            "uuid" => uuid,
            "displayTime" => Time.new.to_i
        }
        filepath = "#{Config::pathToCatalystDataRepository()}/Wave-Control/#{CommonUtils::timeStringL22()}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }
        object
    end

    # WavesControl::isNotShowing(uuid)
    def self.isNotShowing(uuid)
        Find.find("#{Config::pathToCatalystDataRepository()}/Wave-Control") do |path|
            next if path[-5, 5] != ".json"
            object = JSON.parse(IO.read(path))
            if object["uuid"] == uuid then
                FileUtils.rm(path)
            end
        end
    end

    # WavesControl::getRatio(uuid)
    def self.getRatio(uuid)
        object = WavesControl::getObject(uuid)
        timespan = Time.new.to_i - object["displayTime"]
        Math.exp(-timespan.to_f/86400)
    end
end
