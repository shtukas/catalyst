# encoding: UTF-8

class Items

    # Items::init(uuid)
    def self.init(uuid)
        Blades::spawn_new_blade(uuid)
        Index::setAttribute(uuid, "uuid", uuid)
    end

    # Items::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        item = Index::itemOrNull(uuid)
        return item if item
        puts "Looking for item uuid: #{uuid} in the blades".yellow
        item = Blades::getItemOrNull(uuid)
        if item then
            puts "Found uuid #{uuid}".yellow
            Index::commitItemToIndex(item)
        end
        item
    end

    # Items::items()
    def self.items()
        Index::items()
    end

    # Items::mikuType(mikuType)
    def self.mikuType(mikuType)
        Index::mikuType(mikuType)
    end

    # Items::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        version = Time.new.to_f
        item = Blades::getItemOrNull(uuid)
        if item.nil? then
            Index::destroy(uuid)
            return
        end
        item[attrname] = attrvalue
        item["catalyst:version"] = version
        Blades::commitItemToDisk(item)
        Index::setAttribute(uuid, attrname, attrvalue)
        Index::setAttribute(uuid, "catalyst:version", version)
    end

    # Items::destroy(uuid)
    def self.destroy(uuid)
        Blades::destroy(uuid)
        Index::destroy(uuid)
    end

    # Items::maintenance()
    def self.maintenance()
        Blades::items_enumerator().each{|blade_item|
            index_item = Index::itemOrNull(blade_item["uuid"])
            if index_item.nil? then
                Index::commitItemToIndex(blade_item)
                next
            end
            if blade_item["catalyst:version"] > index_item["catalyst:version"] then
                Index::commitItemToIndex(blade_item)
            end
        }
    end
end
