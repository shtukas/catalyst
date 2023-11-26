
$DataCenterCatalystItems = {}

class DataCenter

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
        item = Cubes::itemOrNull(uuid)
        return nil if item.nil?
        $DataCenterCatalystItems[uuid] = item
        item
    end

    # DataCenter::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        Cubes::setAttribute(uuid, attrname, attrvalue)
        $DataCenterCatalystItems[uuid][attrname] = attrvalue
        XCache::set("1a777efb-c8a3-47d0-bf9f-67acecf06dc6", JSON.generate($DataCenterCatalystItems))
        nil
    end

    # DataCenter::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        Cubes::itemInit(uuid, mikuType)
        $DataCenterCatalystItems[uuid] = {
            "uuid" => uuid,
            "mikuType" => mikuType
        }
        XCache::set("1a777efb-c8a3-47d0-bf9f-67acecf06dc6", JSON.generate($DataCenterCatalystItems))
    end

    # DataCenter::destroy(uuid)
    def self.destroy(uuid)
        Cubes::destroy(uuid)
        $DataCenterCatalystItems.delete(uuid)
        XCache::set("1a777efb-c8a3-47d0-bf9f-67acecf06dc6", JSON.generate($DataCenterCatalystItems))
    end
end