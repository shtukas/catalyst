
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

    # Config::pathToCatalystDataRepository()
    def self.pathToCatalystDataRepository()
        "#{Config::pathToGalaxy()}/DataHub/Catalyst/data"
    end
end
