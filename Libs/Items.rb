# encoding: UTF-8

class Items

    # Items::init(uuid)
    def self.init(uuid)
        Blades::spawn_new_blade(uuid)
        HardProblem::new_item(uuid)
    end

    # Items::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        Blades::getItemOrNull(uuid)
    end

    # Items::items()
    def self.items()
        items = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047")
        return items if items
        puts "rebuilding items cache".yellow
        items = Blades::items_enumerator().to_a
        ValueCache::set("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047", items)
        items
    end

    # Items::mikuTypes()
    def self.mikuTypes()
        mikuTypes = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:mikuTypes:30cd6e81-4cee-4439-8489-73a1ab8d1dce")
        return mikuTypes if mikuTypes
        puts "rebuilding mikuTypes cache".yellow
        mikuTypes = Blades::items_enumerator().to_a.map{|item| item["mikuType"] }.uniq
        ValueCache::set("#{HardProblem::get_general_prefix()}:mikuTypes:30cd6e81-4cee-4439-8489-73a1ab8d1dce", mikuTypes)
        mikuTypes
    end

    # Items::mikuType(mikuType)
    def self.mikuType(mikuType)
        items = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980")
        return items if items
        puts "rebuilding mikuType: #{mikuType} cache".yellow
        items = Items::items().select{|item| item["mikuType"] == mikuType }
        ValueCache::set("#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980", items)
        items
    end

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
        Blades::destroy(uuid)
        HardProblem::item_has_been_destroyed(uuid)
    end
end
