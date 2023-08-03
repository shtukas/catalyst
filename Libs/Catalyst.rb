

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

    # Catalyst::determineTargetParentUnderneathArgument(reference = nil)
    def self.determineTargetParentUnderneathArgument(reference = nil)

        if reference.nil? then
            core = TxCores::interactivelySelectOneOrNull()
            return nil if core.nil?
            return Catalyst::determineTargetParentUnderneathArgument(core)
        end

        child = LucilleCore::selectEntityFromListOfEntitiesOrNull("children", [reference] + Tx8s::childrenInOrder(reference).first(20), lambda{|i| PolyFunctions::toString(i) })
        return nil if child.nil?

        if child["uuid"] == reference["uuid"] then
            return reference
        end

        if child["mikuType"] == "NxThread" or child["mikuType"] == "NxCore" then
            return Catalyst::determineTargetParentUnderneathArgument(child)
        end

        Catalyst::determineTargetParentUnderneathArgument(reference) # redoing the same operation because we didn't select the reference or a container
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
