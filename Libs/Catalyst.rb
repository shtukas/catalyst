

class Catalyst

    # Catalyst::mikuTypes()
    def self.mikuTypes()
        [
          "NxAnniversary",
          "NxIce",
          "NxLine",
          "NxOndate",
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

    # Catalyst::moveTaskables(items, parent or nil)
    def self.moveTaskables(items, parent = nil)
        if items.any?{|item| !["NxOndate", "NxBurner", "NxTask", "NxThread"].include?(item["mikuType"]) } then
            puts "Moving items should be either NxOndate, NxBurner, NxTask or NxThread"
            LucilleCore::pressEnterToContinue()
            return
        end

        if parent.nil? then
            parent = TxCores::interactivelySelectOneOrNull()
            return if parent.nil?
            Catalyst::moveTaskables(items, parent)
            return
        end

        loop {
            system("clear")
            parentKids = Todos::children(parent).sort_by{|item| item["coordinate-nx129"] || 0 }
            puts "parent: #{PolyFunctions::toString(parent).green}"
            puts "kids:"
            parentKids.each_with_index{|i, indx| puts "  - (#{indx}) #{PolyFunctions::toString(i)}"}
            puts ""
            puts "> here | make thread here | go to <n> # of thread to go in"
            command = STDIN.gets().strip
            if command == "here" then
                items.each{|item|
                    if item["mikuType"] == "NxBurner" then
                        Cubes::setAttribute2(item["uuid"], "mikuType", "NxTask")
                    end
                    if item["mikuType"] == "NxOndate" then
                        Cubes::setAttribute2(item["uuid"], "mikuType", "NxTask")
                    end
                    Cubes::setAttribute2(item["uuid"], "lineage-nx128", parent["uuid"])
                }
                if items.size == 1 then
                    item = items[0]
                    position = NxThreads::interactivelyDecidePositionAtThread(parent)
                    Cubes::setAttribute2(item["uuid"], "coordinate-nx129", position)
                end
                return
            end
            if command == "make thread here" then
                position = NxThreads::interactivelyDecidePositionAtThread(parent)
                thread = NxThreads::interactivelyIssueNewOrNull()
                next if thread.nil?
                Cubes::setAttribute2(thread["uuid"], "lineage-nx128", parent["uuid"])
                Cubes::setAttribute2(thread["uuid"], "coordinate-nx129", position)
                next
            end
            if command.start_with?("go to") then
                indx = command[5, 99].strip.to_i
                target = parentKids[indx]
                next if target.nil?
                Catalyst::moveTaskables(items, target)
                return
            end
        }
    end
end
