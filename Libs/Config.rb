
# encoding: UTF-8

class Config

    # Config::userHomeDirectory()
    def self.userHomeDirectory()
        ENV['HOME']
    end

    # Config::pathToDesktop()
    def self.pathToDesktop()
        "#{Config::userHomeDirectory()}/Desktop"
    end

    # Config::pathToGalaxy()
    def self.pathToGalaxy()
        "#{Config::userHomeDirectory()}/Galaxy"
    end

    # Config::pathToNyx()
    def self.pathToNyx()
        "#{Config::pathToGalaxy()}/Nyx"
    end

    # Config::configFilepath()
    def self.configFilepath()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-Config.json"
    end

    # Config::getOrNull(key)
    def self.getOrNull(key)
        config = JSON.parse(IO.read(Config::configFilepath()))
        config[key]
    end

    # Config::set(key, value)
    def self.set(key, value)
        config = JSON.parse(IO.read(Config::configFilepath()))
        config[key] = value
        File.open(Config::configFilepath(), "w"){|f| f.puts(JSON.pretty_generate(config)) }
    end

    # Config::thisInstanceId()
    def self.thisInstanceId()
        object = JSON.parse(IO.read("#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-Config.json"))
        if object["instanceId"].nil? then
            raise "(error e6d6caec-397f-48d2-9e6d-60d4b8716eb5)"
        end
        object["instanceId"]
    end

    # Config::isPrimaryInstance()
    def self.isPrimaryInstance()
        Config::thisInstanceId() == "Lucille24-pascal"
    end

    # Config::pathToCatalystDataRepository()
    def self.pathToCatalystDataRepository()
        dir1 = "/Users/Shared/Galaxy/DataHub/catalyst"
        if File.exist?(dir1) then
            return dir1
        end
        dir2 = "#{Config::userHomeDirectory()}/x-space/Dx004/DataHub/catalyst"
        if File.exist?(dir2) then
            return dir2
        end
        raise "(Error 3D436606-CBE2-4B77-852D-02E657CAFC54)"
    end
end
