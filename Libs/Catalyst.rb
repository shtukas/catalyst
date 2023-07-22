

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
end
