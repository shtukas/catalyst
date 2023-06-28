

class Catalyst

    # Catalyst::catalystItems()
    def self.catalystItems()
        [
          "NxAnniversary",
          "NxBackup",
          "NxOndate",
          "NxTask",
          "PhysicalTarget",
          "Wave",
        ]
            .map{|mikuType|
                DarkEnergy::mikuType(mikuType)
            }
            .flatten
    end

    # Catalyst::fsckItem(item)
    def self.fsckItem(item)
        CoreData::fsck(item)
    end

    # Catalyst::fsck()
    def self.fsck()
        # We use a .to_a here because otherwise the error is not propagated up (Ruby weirdness)
        Catalyst::catalystItems().each{|item|
            Catalyst::fsckItem(item)
        }
    end
end
