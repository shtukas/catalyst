

class Catalyst

    # Catalyst::mikuTypes()
    def self.mikuTypes()
        [
          "NxAnniversary",
          "NxBackup",
          "NxIce",
          "NxOndate",
          "NxPure",
          "NxTask",
          "NxThread",
          "PhysicalTarget",
          "TxCore",
          "Wave"
        ]
    end

    # Catalyst::catalystItems()
    def self.catalystItems()
        Catalyst::mikuTypes()
            .map{|mikuType| Cubes::mikuType(mikuType) }
            .flatten
    end

    # Catalyst::selectChildUnderneathParentOrNull(parent = nil)
    def self.selectChildUnderneathParentOrNull(parent = nil)

        if parent.nil? then
            return TxCores::interactivelySelectOneOrNull()
        end

        LucilleCore::selectEntityFromListOfEntitiesOrNull("children", Tx8s::childrenInOrder(parent).first(20), lambda{|i| PolyFunctions::toString(i) })
    end

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
                next if Cubes::itemOrNull(itemuuid)
                item = NxTasks::descriptionToTask_vX(itemuuid, "(open cycle: dir) #{locationname}")
                puts JSON.pretty_generate(item)
            end

            if File.file?(location) then
                itemuuid = Digest::SHA1.hexdigest("#{locationname}:c54c9b05-c914-4df5-b77a-6e72f2d43cf7")
                next if Cubes::itemOrNull(itemuuid)
                item = NxTasks::descriptionToTask_vX(itemuuid, "(open cycle: file) #{locationname}")
                puts JSON.pretty_generate(item)
            end

        }
    end

    # Catalyst::listingCompletionRatio(item)
    def self.listingCompletionRatio(item)
        if item["mikuType"] == "NxTask" then
            return Bank::recoveredAverageHoursPerDay(item["uuid"])
        end
        if item["mikuType"] == "NxThread" then
            hours = item["hours"] || 2
            return Bank::recoveredAverageHoursPerDay(item["uuid"]).to_f/(hours.to_f/7)
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
            Cubes::setAttribute2(item["uuid"], key, value)
        }
    end

    # Catalyst::postpone(item)
    def self.postpone(item)
        cursor = XCache::getOrDefaultValue("d74ae03d-24b7-4485-bf93-6c397ca4dc1c", "0").to_i
        cursor = [cursor + 3600, Time.new.to_i + 3600].max
        puts "Pushed to #{Time.at(cursor).to_s}"
        DoNotShowUntil::setUnixtime(item, cursor)
        XCache::set("d74ae03d-24b7-4485-bf93-6c397ca4dc1c", cursor)
    end

    # Catalyst::deQueue(item)
    def self.deQueue(item)
        return if item["ordinal-1324"].nil?
        Cubes::setAttribute2(item["uuid"], "ordinal-1324", nil)
    end
end
