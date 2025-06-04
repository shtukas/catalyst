# encoding: UTF-8

class Items

    # ----------------------------------------
    # Core

    # Items::commitItemToDisk(item)
    def self.commitItemToDisk(item)
        blade_filepath = Blades::uuidToBladeFilepathOrNull(item["uuid"])
        if blade_filepath.nil? then
            # We do not have a file yet. Let's make one
            blade_filepath = Blades::spawn_new_blade(item["uuid"])
        end
        Blades::commitItemToItsBladeFile(item)
    end

    # ----------------------------------------
    # Interface

    # Items::init(uuid)
    def self.init(uuid)
        Blades::spawn_new_blade(uuid)
    end

    # Items::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        Blades::getItemOrNull(uuid)
    end

    # Items::items_enumerator()
    def self.items_enumerator()
        Blades::items_enumerator()
    end

    # Items::mikuType(mikuType)
    def self.mikuType(mikuType)
        items = ValueCacheWithExpiry::getOrNull("1daf4e98-9e88-4b2c-bb87-585e7d30acb4:#{mikuType}", 1200)
        return items if items
        items = Blades::items_enumerator().select{|item| item["mikuType"] == mikuType }
        ValueCacheWithExpiry::set("1daf4e98-9e88-4b2c-bb87-585e7d30acb4:#{mikuType}", items)
        items
    end

    # Items::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        item = Items::itemOrNull(uuid)
        return if item.nil?
        item[attrname] = attrvalue
        Items::commitItemToDisk(item)
    end

    # Items::destroy(uuid)
    def self.destroy(uuid)
        Blades::destroy(uuid)
    end
end
