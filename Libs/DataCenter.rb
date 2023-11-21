
$DataCenterCatalystItems = {}
$DataCenterListingItems = {}

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
        $DataCenterCatalystItems[uuid]
    end

    # DataCenter::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        Cubes::setAttribute(uuid, attrname, attrvalue)
        $DataCenterCatalystItems[uuid][attrname] = attrvalue
        if $DataCenterListingItems[uuid] then
            $DataCenterListingItems[uuid][attrname] = attrvalue
        end
        XCache::set("1a777efb-c8a3-47d0-bf9f-67acecf06dc6", JSON.generate($DataCenterCatalystItems))
        XCache::set("6d02e327-e07a-4168-be13-d9e7f367c6f8", JSON.generate($DataCenterListingItems))
        nil
    end

    # DataCenter::itemInit(uuid, mikuType)
    def self.itemInit(uuid, mikuType)
        Cubes::itemInit(uuid, mikuType)
        $DataCenterCatalystItems[uuid] = {
            "uuid" => uuid,
            "mikuType" => mikuType
        }
        $DataCenterListingItems[uuid] = {
            "uuid" => uuid,
            "mikuType" => mikuType
        }
        XCache::set("1a777efb-c8a3-47d0-bf9f-67acecf06dc6", JSON.generate($DataCenterCatalystItems))
        XCache::set("6d02e327-e07a-4168-be13-d9e7f367c6f8", JSON.generate($DataCenterListingItems))
    end

    # DataCenter::destroy(uuid)
    def self.destroy(uuid)
        Cubes::destroy(uuid)
        $DataCenterCatalystItems.delete(uuid)
        $DataCenterListingItems.delete(uuid)
        XCache::set("1a777efb-c8a3-47d0-bf9f-67acecf06dc6", JSON.generate($DataCenterCatalystItems))
        XCache::set("6d02e327-e07a-4168-be13-d9e7f367c6f8", JSON.generate($DataCenterListingItems))
    end
end