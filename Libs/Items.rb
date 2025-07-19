# encoding: UTF-8

class Items

    # Items::init(uuid)
    def self.init(uuid)
        Blades::spawn_new_blade(uuid)
    end

    # -------------------------------------
    # Getters (should remain indices free)

    # Items::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        Blades::getItemOrNull(uuid)
    end

    # Items::items()
    def self.items()
        Blades::items()
    end

    # Items::mikuTypes()
    def self.mikuTypes()
        Blades::items().map{|item| item["mikuType"] }.uniq
    end

    # Items::mikuType(mikuType)
    def self.mikuType(mikuType)
        Items::items().select{|item| item["mikuType"] == mikuType }
    end

    # -------------------------------------
    # Setters (should update indices when relevant)

    # Items::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        item = Blades::getItemOrNull(uuid)
        if item.nil? then
            HardProblem::item_could_not_be_found_on_disk(uuid)
            return
        end
        item[attrname] = attrvalue
        Blades::commitItemToDisk(item)
        HardProblem::item_attribute_has_been_updated(uuid, attrname, attrvalue)
    end

    # Items::destroy(uuid)
    def self.destroy(uuid)
        item = Items::itemOrNull(uuid)
        if item then
            HardProblem::item_is_being_destroyed(item)
        end
        Blades::destroy(uuid)
        HardProblem::item_has_been_destroyed(uuid)
    end
end
