

class Catalyst

    # Catalyst::maintenance()
    def self.maintenance()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/OpenCycles").each{|location|
            locationname = File.basename(location)
            next if locationname[0, 1] == "."

            if File.directory?(location) then
                markerfilepath = "#{location}/.catalystItemUUID8ba92694"
                if File.exist?(markerfilepath) then
                    itemuuid = IO.read(markerfilepath).strip
                else
                    itemuuid = SecureRandom.uuid
                    File.open(markerfilepath, "w"){|f| f.write(itemuuid) }
                end
                next if Catalyst::itemOrNull(itemuuid)
                item = NxTasks::descriptionToTask1(itemuuid, "(open cycle: dir) #{locationname}")
                puts JSON.pretty_generate(item)
            end

            if File.file?(location) then
                itemuuid = Digest::SHA1.hexdigest("#{locationname}:c54c9b05-c914-4df5-b77a-6e72f2d43cf7")
                next if Catalyst::itemOrNull(itemuuid)
                item = NxTasks::descriptionToTask1(itemuuid, "(open cycle: file) #{locationname}")
                puts JSON.pretty_generate(item)
            end

        }
    end

    # Catalyst::listingCompletionRatio(item)
    def self.listingCompletionRatio(item)
        if item["mikuType"] == "NxTask" then
            return Bank::recoveredAverageHoursPerDay(item["uuid"])
        end
        if item["mikuType"] == "TxCore" then
            hours = item["hours"]
            return Bank::recoveredAverageHoursPerDay(item["uuid"]).to_f/(hours.to_f/6)
        end
        raise "(error: 3b1e3b09-1472-48ef-bcbb-d98c8d170056) with item: #{item}"
    end

    # Catalyst::editItem(item)
    def self.editItem(item)
        item = JSON.parse(CommonUtils::editTextSynchronously(JSON.pretty_generate(item)))
        item.to_a.each{|key, value|
            Events::publishItemAttributeUpdate(item["uuid"], key, value)
        }
    end

    # Catalyst::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        EventTimelineDatasets::catalystItems()[uuid].clone
    end

    # Catalyst::mikuType(mikuType)
    def self.mikuType(mikuType)
        EventTimelineDatasets::catalystItems().values.select{|item| item["mikuType"] == mikuType }
    end

    # Catalyst::destroy(uuid)
    def self.destroy(uuid)
        Events::publishItemDestroy(uuid)
    end

    # Catalyst::catalystItems()
    def self.catalystItems()
        EventTimelineDatasets::catalystItems().values
    end

    # Catalyst::newGlobalFirstPosition()
    def self.newGlobalFirstPosition()
        t = Catalyst::catalystItems()
                .select{|item| item["global-position"] }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].min}
        t - 1
    end

    # Catalyst::newGlobalLastPosition()
    def self.newGlobalLastPosition()
        t = Catalyst::catalystItems()
                .select{|item| item["global-position"] }
                .map{|item| item["global-position"] }
                .reduce(0){|number, x| [number, x].max }
        t + 1
    end
end
