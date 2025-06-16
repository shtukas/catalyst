

# ValueCache(d)

# Items
#      : "items:4d32-9154-5fc5efb7e047"

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

        HardProblem::updateMikuTypesItemsWithItem(item)

        # Updating a parent's children inventory
        if attribute == "nx1949" then
            parentuuid = value["parentuuid"]
            ValueCache::destroy("#{HardProblem::get_general_prefix()}:children-for-parent:e76c2bdb-b869-429f-9889:#{parentuuid}")
        end

        # Updating a parent's children inventory
        if attribute == "mikuType" then
            mikuType = value
            directory = "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/HardProblem/MikuTypes/#{mikuType}"
            if !File.exist?(directory) then
                FileUtils.mkpath(directory)
            end
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

        HardProblem::updateMikuTypesItemsWithItem(item)
    end

    # HardProblem::blade_has_been_destroyed(uuid)
    def self.blade_has_been_destroyed(uuid)
        items = ValueCache::getOrNull("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047")
        if items then
            items = items.reject{|item| item["uuid"] == uuid }
            ValueCache::set("#{HardProblem::get_general_prefix()}:items:4d32-9154-5fc5efb7e047", items)
        end

        HardProblem::updateMikuTypesItemsItemRemoval(uuid)
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

        HardProblem::updateMikuTypesItemsItemRemoval(uuid)
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

        HardProblem::updateMikuTypesItemsItemRemoval(uuid)

        Dispatch::dispatch({
            "unixtime" => Time.new.to_i,
            "type"     => "destroy",
            "uuid"     => uuid
        })
    end

    # HardProblem::retrieveUniqueJsonFileInDirectoryOrNullDestroyMultiple(directory)
    def self.retrieveUniqueJsonFileInDirectoryOrNullDestroyMultiple(directory)
        return nil if !File.exist?(directory)
        filepaths = LucilleCore::locationsAtFolder(directory)
            .select{|filepath| filepath[-5, 5] == ".json" }
        if filepaths.size > 1 then
            filepaths.each{|filepath|
                FileUtils.rm(filepath)
            }
            return nil
        end
        filepaths[0]
    end

    # HardProblem::commitJsonDataToDiskContentAddressed(directory, data)
    def self.commitJsonDataToDiskContentAddressed(directory, data)
        if !File.exist?(directory) then
            FileUtils.mkpath(directory)
        end
        content = JSON.pretty_generate(data)
        filename = "#{Digest::SHA1.hexdigest(content)}.json"
        filepath = "#{directory}/#{filename}"
        File.open(filepath, "w"){|f| f.puts(content) }
    end

    # HardProblem::updateMikuTypesItemsWithItem(item)
    def self.updateMikuTypesItemsWithItem(item)
        # Updating data/HardProblem/MikuTypes
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Catalyst/data/HardProblem/MikuTypes")
            .select{|filepath| !File.basename(filepath).start_with?('.') }
            .each{|mikuTypeDirectory|
                mikuType = File.basename(mikuTypeDirectory)
                LucilleCore::locationsAtFolder(mikuTypeDirectory)
                    .select{|filepath| filepath[-5, 5] == ".json" }
                    .each{|filepath|
                        items = JSON.parse(IO.read(filepath))
                        items = items.reject{|i| i["uuid"] == uuid }
                        if item["mikuType"] == mikuType then
                            items = items + [item]
                        end
                        HardProblem::commitJsonDataToDiskContentAddressed(mikuTypeDirectory, items)
                    }
            }
    end

    # HardProblem::updateMikuTypesItemsItemRemoval(uuid)
    def self.updateMikuTypesItemsItemRemoval(uuid)
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Catalyst/data/HardProblem/MikuTypes")
            .select{|filepath| !File.basename(filepath).start_with?('.') }
            .each{|mikuTypeDirectory|
                mikuType = File.basename(mikuTypeDirectory)
                LucilleCore::locationsAtFolder(mikuTypeDirectory)
                .select{|filepath| filepath[-5, 5] == ".json" }
                .each{|filepath|
                    items = JSON.parse(IO.read(filepath))
                    items = items.reject{|i| i["uuid"] == uuid }
                    HardProblem::commitJsonDataToDiskContentAddressed(mikuTypeDirectory, items)
                }
            }
    end
end
