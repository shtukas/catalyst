
$DataCenterCatalystItems = {}

class DataCenter

    # DataCenter::reload()
    def self.reload()
        data = {}
        Cubes::items()
            .each{|item|
                data[item["uuid"]] = item
            }
        $DataCenterCatalystItems = data
    end

    # DataCenter::mikuTypes()
    def self.mikuTypes()
        $DataCenterCatalystItems.values.map{|item| item["mikuType"] }.uniq
    end

    # DataCenter::mikuType(mikuType)
    def self.mikuType(mikuType)
        $DataCenterCatalystItems.values.select{|item| item["mikuType"] == mikuType }
    end

    # DataCenter::catalystItems()
    def self.catalystItems()
        $DataCenterCatalystItems.values
    end

    # DataCenter::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        $DataCenterCatalystItems[uuid]
    end

    # DataCenter::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        Cubes::setAttribute(uuid, attrname, attrvalue)
        $DataCenterCatalystItems[uuid][attrname] = attrvalue
        nil
    end

    # DataCenter::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        Cubes::itemInit(uuid, mikuType)
        $DataCenterCatalystItems[uuid] = {
            "uuid" => uuid,
            "mikuType" => mikuType
        }
    end

    # DataCenter::destroy(uuid)
    def self.destroy(uuid)
        Cubes::destroy(uuid)
        $DataCenterCatalystItems.delete(uuid)
    end
end