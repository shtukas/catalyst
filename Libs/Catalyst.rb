

class Catalyst

    # Catalyst::mikuTypes()
    def self.mikuTypes()
        [
          "NxAnniversary",
          "NxBackup",
          "NxDelegate",
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
            .map{|mikuType| BladesGI::mikuType(mikuType) }
            .flatten
    end

    # Catalyst::fsck()
    def self.fsck()
        Waves::fsck()
        NxTasks::fsck()
        NxOndates::fsck()
        BladesGI::mikuType("NxIce").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end

    # Catalyst::determineParentOrNull_identityOrChild(reference = nil)
    def self.determineParentOrNull_identityOrChild(reference = nil)

        if reference.nil? then
            core = TxCores::interactivelySelectOneOrNull()
            return nil if core.nil?
            return Catalyst::determineParentOrNull_identityOrChild(core)
        end

        puts "cursor:"
        puts PolyFunctions::toString(reference)

        cursorChildren = Tx8s::childrenInOrder(reference)
        cursorChildrenThreads = cursorChildren.select{|item| item["mikuType"] == "NxThread" }
        return reference if cursorChildrenThreads.empty?

        puts "children threads:"
        cursorChildrenThreads.each{|child|
            puts "- #{PolyFunctions::toString(child)}"
        }

        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["place at cursor ^", "put inside a child thread"])

        return nil if option.nil?

        if option == "place at cursor ^" then
            return reference
        end

        if option == "put inside a child thread" then
            child = LucilleCore::selectEntityFromListOfEntitiesOrNull("children", cursorChildrenThreads, lambda{|i| PolyFunctions::toString(i) })
            if child then
                return Catalyst::determineParentOrNull_identityOrChild(child)
            else
                return reference
            end
        end

        raise "(error: 6a405195-84e2-4eb0-b818-24f8996f5615)"
    end

    # Catalyst::maintenance()
    def self.maintenance()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/OpenCycles").each{|location|
            locationname = File.basename(location)
            next if locationname[0, 1] == "."
            itemUUIDLocation = "#{location}/.catalystItemUUID8ba92694"
            if File.exist?(itemUUIDLocation) then
                itemuuid = IO.read(itemUUIDLocation).strip
                next if BladesGI::itemOrNull(itemuuid)
            end
            items = BladesGI::mikuType("NxTask") + BladesGI::mikuType("NxOndate") + BladesGI::mikuType("Wave")
            next if items.any?{|item| (item["description"] || "").include?(locationname) }
            item = NxTasks::descriptionToTask("(open cycle) #{locationname}")
            puts JSON.pretty_generate(item)
            File.open(itemUUIDLocation, "w"){|f| f.write(item["uuid"]) }
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
            return Bank::recoveredAverageHoursPerDay(item["uuid"]).to_f/((item["hours"]*3600).to_f/6)
        end
        raise "(error: 3b1e3b09-1472-48ef-bcbb-d98c8d170056) with item: #{item}"
    end
end
