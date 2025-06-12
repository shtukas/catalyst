

# ValueCache(d)

# Items
#      : "items:4d32-9154-5fc5efb7e047"
#      : "#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980"
#      : "#{HardProblem::get_general_prefix()}:mikuTypes:30cd6e81-4cee-4439-8489-73a1ab8d1dce"

class HardProblem

    # HardProblem::get_general_prefix()
    def self.get_general_prefix()
        prefix = XCache::getOrNull("049bdc08-8833-4736-aa90-4dc2c59fd67d:#{CommonUtils::today()}")
        if prefix.nil? then
            prefix = SecureRandom.hex
            XCache::set("049bdc08-8833-4736-aa90-4dc2c59fd67d:#{CommonUtils::today()}", prefix)
        end
        prefix
    end

    # HardProblem::new_item(uuid)
    def self.new_item(uuid)

    end

    # HardProblem::item_attribute_has_been_updated(uuid, attribute, value)
    def self.item_attribute_has_been_updated(uuid, attribute, value)
        puts "hard problem: item attribute update (#{uuid}, #{attribute}, #{value})".yellow
        item = Blades::getItemOrNull(uuid)
        return if item.nil?

        # Updating items in "items:4d32-9154-5fc5efb7e047"
        items = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047")
        if items then
            items = items.reject{|i| i["uuid"] == uuid } + [item]
            ValueCache::set("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047", items)
        end

        # Updating elements in "#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980"
        Items::mikuTypes().each{|mikuType|
            items = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980")
            if items then
                items = items.reject{|i| i["uuid"] == uuid }
                if item["mikuType"] == mikuType then
                    items = items + [item]
                end
                ValueCache::set("#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980", items)
            end
        }

        # Updating the list of mikuTypes, if needed
        if attribute == "mikuType" then
            mikuTypes = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:mikuTypes:30cd6e81-4cee-4439-8489-73a1ab8d1dce")
            mikuTypes = (mikuTypes + [value]).uniq
            ValueCache::set("#{HardProblem::get_general_prefix()}:mikuTypes:30cd6e81-4cee-4439-8489-73a1ab8d1dce", mikuTypes)
        end

        # Updating a parent's children inventory
        if attribute == "nx1949" then
            parentuuid = value["parentuuid"]
            ValueCache::destroy("#{HardProblem::get_general_prefix()}:children-for-parent:e76c2bdb-b869-429f-9889:#{parentuuid}")
        end

        Dispatch::dispatch({
            "unixtime" => Time.new.to_i,
            "type"     => "update",
            "uuid"     => uuid
        })
    end

    # HardProblem::blade_has_been_updated(uuid)
    def self.blade_has_been_updated(uuid)
        item = Blades::getItemOrNull(uuid)
        return if item.nil?

        # Updating items in "items:4d32-9154-5fc5efb7e047"
        items = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047")
        if items then
            items = [item] + items
            items = items.reduce([]){|selected_items, item|
                if selected_items.map{|i| i["uuid"] }.include?(item["uuid"]) then
                    selected_items
                else
                    selected_items + [item]
                end
            }
            ValueCache::set("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047", items)
        end

        # Updating elements in "#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980"
        Items::mikuTypes().each{|mikuType|
            items = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980")
            if items then
                if item["mikuType"] == mikuType then
                    items = [item] + items
                    items = items.reduce([]){|selected_items, item|
                        if selected_items.map{|i| i["uuid"] }.include?(item["uuid"]) then
                            selected_items
                        else
                            selected_items + [item]
                        end
                    }
                end
                ValueCache::set("#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980", items)
            end
        }
    end

    # HardProblem::blade_has_been_destroyed(uuid)
    def self.blade_has_been_destroyed(uuid)
        # Updating items in "items:4d32-9154-5fc5efb7e047"
        items = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047")
        if items then
            items = items.reject{|item| item["uuid"] == uuid }
            ValueCache::set("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047", items)
        end

        # Updating elements in "#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980"
        Items::mikuTypes().each{|mikuType|
            items = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980")
            if items then
                items = items.reject{|item| item["uuid"] == uuid }
                ValueCache::set("#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980", items)
            end
        }


    end

    # HardProblem::item_is_being_destroyed(item)
    def self.item_is_being_destroyed(item)
        HardProblem::blade_has_been_destroyed(item["uuid"])

        if item["nx1949"] then
            # Updating a parent's children
            ValueCache::destroy("#{HardProblem::get_general_prefix()}:children-for-parent:e76c2bdb-b869-429f-9889:#{item["nx1949"]["parentuuid"]}")
        end
    end

    # HardProblem::item_could_not_be_found_on_disk(uuid)
    def self.item_could_not_be_found_on_disk(uuid)

        puts "hard problem: item could not be found on disk (#{uuid})".yellow

        # Updating items in "items:4d32-9154-5fc5efb7e047"
        items = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047")
        if items then
            items = items.reject{|item| item["uuid"] == uuid }
            ValueCache::set("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047", items)
        end

        # Updating elements in "#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980"
        Items::mikuTypes().each{|mikuType|
            items = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980")
            if items then
                items = items.reject{|item| item["uuid"] == uuid }
                ValueCache::set("#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980", items)
            end
        }
    end

    # HardProblem::item_has_been_destroyed(uuid)
    def self.item_has_been_destroyed(uuid)

        puts "hard problem: item has been destroyed (#{uuid})".yellow

        # Updating items in "items:4d32-9154-5fc5efb7e047"
        items = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047")
        if items then
            items = items.reject{|item| item["uuid"] == uuid }
            ValueCache::set("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047", items)
        end

        # Updating elements in "#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980"
        Items::mikuTypes().each{|mikuType|
            items = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980")
            if items then
                items = items.reject{|item| item["uuid"] == uuid }
                ValueCache::set("#{HardProblem::get_general_prefix()}:mikuType:#{mikuType}:452f-a0df-7a23e3e4e980", items)
            end
        }

        Dispatch::dispatch({
            "unixtime" => Time.new.to_i,
            "type"     => "destroy",
            "uuid"     => uuid
        })
    end
end
