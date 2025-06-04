# encoding: UTF-8

class Items

    # Items::init(uuid)
    def self.init(uuid)
        Blades::spawn_new_blade(uuid)
    end

    # Items::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        Index::itemOrNull(uuid)
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
        item = Blades::getItemOrNull(uuid)
        if item.nil? then
            Index::destroy(uuid)
            return
        end
        item[attrname] = attrvalue
        Blades::commitItemToDisk(item)
        Index::setAttribute(uuid, attrname, attrvalue)
    end

    # Items::destroy(uuid)
    def self.destroy(uuid)
        Blades::destroy(uuid)
        Index::destroy(uuid)
    end
end
