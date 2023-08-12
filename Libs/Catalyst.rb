

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
            hours = item["hours"]
            return Bank::recoveredAverageHoursPerDay(item["uuid"]).to_f/(hours.to_f/6)
        end
        raise "(error: 3b1e3b09-1472-48ef-bcbb-d98c8d170056) with item: #{item}"
    end
end
