
$DataCenterCatalystItems = nil

class DataCenter

    # DataCenter::loadCatalystItems()
    def self.loadCatalystItems()
        $DataCenterCatalystItems = Cubes::items()
    end

    # DataCenter::mikuTypes()
    def self.mikuTypes()
        $DataCenterCatalystItems.map{|item| item["mikuType"] }.uniq
    end

    # DataCenter::mikuType(mikuType)
    def self.mikuType(mikuType)
        $DataCenterCatalystItems.select{|item| item["mikuType"] == mikuType }
    end

    # DataCenter::catalystItems()
    def self.catalystItems()
        $DataCenterCatalystItems
    end

    # DataCenter::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        $DataCenterCatalystItems.select{|item| item["uuid"] == uuid }.first
    end

    # DataCenter::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        Cubes::setAttribute(uuid, attrname, attrvalue)
        $DataCenterCatalystItems = $DataCenterCatalystItems.map{|item|
            if item["uuid"] == uuid then
                item[attrname] = attrvalue
            end
            item
        }
        nil
    end

    # DataCenter::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        Cubes::itemInit(uuid, mikuType)
        $DataCenterCatalystItems << {
            "uuid" => uuid,
            "mikuType" => mikuType
        }
    end

    # DataCenter::destroy(uuid)
    def self.destroy(uuid)
        Cubes::destroy(uuid)
        $DataCenterCatalystItems = $DataCenterCatalystItems.reject{|item| item["uuid"] == uuid }
    end
end