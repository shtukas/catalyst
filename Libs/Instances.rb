
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

    # Instances::setInstancesForItem(item)
    def self.setInstancesForItem(item)
        instances = Instances::interactivelySelectOneOrMoreInstanceIds()
        Items::setAttribute(item["uuid"], "instances-58", instances)
    end

    # Instances::suffix(item)
    def self.suffix(item)
        return "" if item["instances-58"].nil?
        " [instances: #{item["instances-58"].join(", ")}]".yellow
    end

    # Instances::canShowHere(item)
    def self.canShowHere(item)
        return true if item["instances-58"].nil?
        item["instances-58"].include?(Instances::thisInstanceId())
    end
end
