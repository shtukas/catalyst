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
        Blades::items_enumerator()
            .select{|item| item["mikuType"] == mikuType }
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
