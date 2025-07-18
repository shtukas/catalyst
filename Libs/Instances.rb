
# encoding: UTF-8

class Instances

    # Instances::thisInstanceId()
    def self.thisInstanceId()
        object = JSON.parse(IO.read("#{Config::pathToGalaxy()}/DataBank/Stargate-Config.json"))
        if object["instanceId"].nil? then
            raise "(error e6d6caec-397f-48d2-9e6d-60d4b8716eb5)"
        end
        object["instanceId"]
    end

    # Instances::instanceIds()
    def self.instanceIds()
        JSON.parse(IO.read("#{Config::pathToCatalystDataRepository()}/instanceIds.json"))
    end

    # Instances::interactivelySelectOneOrMoreInstanceIds()
    def self.interactivelySelectOneOrMoreInstanceIds()
        selected, _ = LucilleCore::selectZeroOrMore("instances", [], Instances::instanceIds())
        selected
    end
end
