

class Catalyst

    # Catalyst::mikuTypes()
    def self.mikuTypes()
        [
          "NxAnniversary",
          "NxBackup",
          "NxDelegate",
          "NxIce",
          "NxLongTask",
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
        NxLongTasks::fsck()
        BladesGI::mikuType("NxIce").each{|item|
            CoreDataRefStrings::fsck(item)
        }
    end

    # Catalyst::selectParentOrNull()
    def self.selectParentOrNull()
        core = TxCores::interactivelySelectOneOrNull()
        return nil if core.nil?
        threads = Tx8s::childrenInOrder(core)
                    .select{|item| item["mikuType"] == "NxThread" }
        return core if threads.empty?
        thread = LucilleCore::selectEntityFromListOfEntitiesOrNull("thread", threads, lambda{|thread| PolyFunctions::toString(thread) })
        return core if thread.nil?
        thread
    end

    # Catalyst::maintenance()
    def self.maintenance()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/OpenCycles").each{|location|
            next if location[0, 1] == "."
            locationname = File.basename(location)
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
end
