
# encoding: UTF-8

class Config

    # Config::userHomeDirectory()
    def self.userHomeDirectory()
        ENV['HOME']
    end

    # Config::pathToGalaxy()
    def self.pathToGalaxy()
        "#{Config::userHomeDirectory()}/Galaxy"
    end

    # Config::thisInstanceId()
    def self.thisInstanceId()
        object = JSON.parse(IO.read("#{Config::pathToGalaxy()}/DataBank/Stargate-Config.json"))
        if object["instanceId"].nil? then
            raise "(error e6d6caec-397f-48d2-9e6d-60d4b8716eb5)"
        end
        object["instanceId"]
    end

    # Config::instanceIds()
    def self.instanceIds()
        JSON.parse(IO.read("#{Config::pathToCatalystDataRepository()}/instanceIds.json"))
    end

    # Config::isPrimaryInstance()
    def self.isPrimaryInstance()
        Config::thisInstanceId() == "Lucille24-pascal"
    end

    # Config::pathToCatalystDataRepository()
    def self.pathToCatalystDataRepository()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data"
    end
end
