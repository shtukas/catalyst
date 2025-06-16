# encoding: UTF-8

class Items

    # Items::init(uuid)
    def self.init(uuid)
        Blades::spawn_new_blade(uuid)
    end

    # Items::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        Blades::getItemOrNull(uuid)
    end

    # Items::items()
    def self.items()
        directory = "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/HardProblem/Items"
        filepath = HardProblem::retrieveUniqueJsonFileInDirectoryOrNullDestroyMultiple(directory)
        if filepath then
            return JSON.parse(IO.read(filepath))
        else
            items = Blades::items()
            HardProblem::commitJsonDataToDiskContentAddressed(directory, items)
            return items
        end
    end

    # Items::mikuTypes()
    def self.mikuTypes()
        mikuTypes = LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/DataHub/Catalyst/data/HardProblem/MikuTypes")
            .select{|filepath| !File.basename(filepath).start_with?('.') }
            .map{|directory2| File.basename(directory2) }
        return mikuTypes
        # Here we are trusting the fact that the data/HardProblem/MikuTypes
        # directory has the list of mikuTypes.
        # If one day we doubt that, we can always run the below and add any missing directories
        mikuTypes = Blades::items().map{|item| item["mikuType"] }.uniq
    end

    # Items::mikuType(mikuType)
    def self.mikuType(mikuType)
        directory = "#{Config::pathToGalaxy()}/DataHub/Catalyst/data/HardProblem/MikuTypes/#{mikuType}"
        filepath = HardProblem::retrieveUniqueJsonFileInDirectoryOrNullDestroyMultiple(directory)
        if filepath then
            return JSON.parse(IO.read(filepath))
        else
            items = Items::items().select{|item| item["mikuType"] == mikuType }
            HardProblem::commitJsonDataToDiskContentAddressed(directory, items)
            return items
        end
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
        item = Items::itemOrNull(uuid)
        if item then
            HardProblem::item_is_being_destroyed(item)
        end
        Blades::destroy(uuid)
        HardProblem::item_has_been_destroyed(uuid)

        directory = "#{Config::userHomeDirectory()}/Galaxy/DataHub/Catalyst/data/HardProblem/Children/#{uuid}"
        LucilleCore::removeFileSystemLocation(directory)
    end
end
