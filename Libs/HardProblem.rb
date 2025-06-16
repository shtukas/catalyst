
class HardProblem

    # HardProblem::item_attribute_has_been_updated(uuid, attribute, value)
    def self.item_attribute_has_been_updated(uuid, attribute, value)
        puts "hard problem: item attribute update (#{uuid}, #{attribute}, #{value})".yellow
        item = Blades::getItemOrNull(uuid)
        return if item.nil?

        HardProblem::updateItemsWithItem(item)
        HardProblem::updateMikuTypesItemsWithItem(item)

        # Updating a parent's children inventory
        if attribute == "nx1949" then
            parentuuid = value["parentuuid"]
            HardProblem::flushAParentChildren(parentuuid)
        end

        # Make sure every mikuType is accounted for
        if attribute == "mikuType" then
            mikuType = value
            directory = "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/HardProblem/MikuTypes/#{mikuType}"
            if !File.exist?(directory) then
                FileUtils.mkpath(directory)
            end
        end
    end

    # HardProblem::blade_has_been_updated(uuid)
    def self.blade_has_been_updated(uuid)
        item = Blades::getItemOrNull(uuid)
        return if item.nil?
        HardProblem::updateItemsWithItem(item)
        HardProblem::updateMikuTypesItemsWithItem(item)
    end

    # HardProblem::blade_has_been_destroyed(uuid)
    def self.blade_has_been_destroyed(uuid)
        HardProblem::updateItemsWithItemRemoval(uuid)
        HardProblem::updateMikuTypesItemsItemRemoval(uuid)
    end

    # HardProblem::item_is_being_destroyed(item)
    def self.item_is_being_destroyed(item)
        HardProblem::blade_has_been_destroyed(item["uuid"])
        if item["nx1949"] then
            HardProblem::flushAParentChildren(item["nx1949"]["parentuuid"])
        end
    end

    # HardProblem::item_could_not_be_found_on_disk(uuid)
    def self.item_could_not_be_found_on_disk(uuid)
        puts "hard problem: item could not be found on disk (#{uuid})".yellow
        HardProblem::updateItemsWithItemRemoval(uuid)
        HardProblem::updateMikuTypesItemsItemRemoval(uuid)
    end

    # HardProblem::item_has_been_destroyed(uuid)
    def self.item_has_been_destroyed(uuid)
        puts "hard problem: item has been destroyed (#{uuid})".yellow
        HardProblem::updateItemsWithItemRemoval(uuid)
        HardProblem::updateMikuTypesItemsItemRemoval(uuid)
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

    # HardProblem::updateItemsWithItem(item)
    def self.updateItemsWithItem(item)
        # Updating data/HardProblem/MikuTypes
        directory = "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/HardProblem/Items"
        LucilleCore::locationsAtFolder(directory)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .each{|filepath|
                items = JSON.parse(IO.read(filepath))
                items = items.reject{|i| i["uuid"] == item["uuid"] }
                items = items + [item]
                FileUtils.rm(filepath)
                HardProblem::commitJsonDataToDiskContentAddressed(directory, items)
            }
    end

    # HardProblem::updateItemsWithItemRemoval(uuid)
    def self.updateItemsWithItemRemoval(uuid)
        # Updating data/HardProblem/MikuTypes
        directory = "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/HardProblem/Items"
        LucilleCore::locationsAtFolder(directory)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .each{|filepath|
                items = JSON.parse(IO.read(filepath))
                items = items.reject{|i| i["uuid"] == item["uuid"] }
                FileUtils.rm(filepath)
                HardProblem::commitJsonDataToDiskContentAddressed(directory, items)
            }
    end

    # HardProblem::updateMikuTypesItemsWithItem(item)
    def self.updateMikuTypesItemsWithItem(item)
        # Updating data/HardProblem/MikuTypes
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Catalyst/data/HardProblem/MikuTypes")
            .select{|filepath| !File.basename(filepath).start_with?('.') }
            .each{|directory2|
                mikuType = File.basename(directory2)
                LucilleCore::locationsAtFolder(directory2)
                    .select{|filepath| filepath[-5, 5] == ".json" }
                    .each{|filepath|
                        items = JSON.parse(IO.read(filepath))
                        items = items.reject{|i| i["uuid"] == uuid }
                        if item["mikuType"] == mikuType then
                            items = items + [item]
                        end
                        FileUtils.rm(filepath)
                        HardProblem::commitJsonDataToDiskContentAddressed(directory2, items)
                    }
            }
    end

    # HardProblem::updateMikuTypesItemsItemRemoval(uuid)
    def self.updateMikuTypesItemsItemRemoval(uuid)
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Catalyst/data/HardProblem/MikuTypes")
            .select{|filepath| !File.basename(filepath).start_with?('.') }
            .each{|directory2|
                mikuType = File.basename(directory2)
                LucilleCore::locationsAtFolder(directory2)
                .select{|filepath| filepath[-5, 5] == ".json" }
                .each{|filepath|
                    items = JSON.parse(IO.read(filepath))
                    items = items.reject{|i| i["uuid"] == uuid }
                    FileUtils.rm(filepath)
                    HardProblem::commitJsonDataToDiskContentAddressed(directory2, items)
                }
            }
    end

    # HardProblem::flushAParentChildren(parentuuid)
    def self.flushAParentChildren(parentuuid)
        directory = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Catalyst/data/HardProblem/Children/#{parentuuid}"
        LucilleCore::removeFileSystemLocation(directory)
    end
end
